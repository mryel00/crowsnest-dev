#!/usr/bin/python3

import argparse
import asyncio
import configparser
import signal
import time
import traceback

from crowsnest import logger, logging_helper, utils, watchdog
from crowsnest.components.crowsnest import Crowsnest


def initial_parse_config(config_path):
    global crowsnest, config
    try:
        config.read(config_path)
    except configparser.ParsingError as e:
        logger.log_multiline(e.message, logger.log_error)
        logger.log_error("Failed to parse config! Exiting...")
        exit(1)
    crowsnest = (
        None if not config.has_section("crowsnest") else Crowsnest(config["crowsnest"])
    )
    if crowsnest is None or not crowsnest.initialized:
        logger.log_error("Failed to parse config for '[crowsnest]' section! Exiting...")
        exit(1)


async def start_sections():
    global config, sect_exec_tasks
    sect_objs = []
    sect_exec_tasks = set()

    # Catches SIGINT and SIGTERM to exit gracefully and cancel all tasks
    signal.signal(signal.SIGINT, exit_gracefully)
    signal.signal(signal.SIGTERM, exit_gracefully)

    try:
        if not len(config.sections()) > 1:
            logger.log_quiet("No Cams / Services to start! Exiting ...")
            return
        logger.log_quiet("Try to parse configured Cams / Services...")
        for section in config.sections():
            section_header = section.split(" ")
            section_object = None
            section_keyword = section_header[0]

            # Skip crowsnest section
            if section_keyword == "crowsnest":
                continue

            log_prefix = f"[{section}]: "
            section_name = " ".join(section_header[1:])
            logger.log_quiet(f"Parse configuration ...", log_prefix)
            component = utils.load_component(
                section_keyword, section_name, config[section]
            )
            if component is not None and component.initialized:
                sect_objs.append(component)
                logger.log_quiet(f"Configuration looks good. Continue ...", log_prefix)
            else:
                logger.log_error(f"Failed to parse config! Skipping ...", log_prefix)

        logger.log_quiet("Try to start configured Cams / Services ...")
        if sect_objs:
            lock = asyncio.Lock()
            for section_object in sect_objs:
                task = asyncio.create_task(section_object.execute(lock))
                sect_exec_tasks.add(task)

            # Lets sect_exec_tasks finish first
            await asyncio.sleep(0)
            async with lock:
                logger.log_quiet("... Done!")
        else:
            logger.log_quiet("No Service started! Exiting ...")

        for task in sect_exec_tasks:
            if task is not None:
                await task
    except Exception as e:
        logger.log_multiline(traceback.format_exc().strip(), logger.log_error)
    finally:
        for task in sect_exec_tasks:
            if task is not None:
                task.cancel()
        watchdog.running = False
        logger.log_quiet("Shutdown or Killed by User!")
        logger.log_quiet("Please come again :)")
        logger.log_quiet("Goodbye...")


def exit_gracefully(signum, frame):
    pass


def check_uptime_and_sleep(sleep_time):
    if sleep_time <= 0:
        return
    try:
        with open("/proc/uptime", "r") as f:
            uptime_seconds = float(f.readline().split()[0])

        if uptime_seconds < 120:
            time.sleep(sleep_time)
    except (IOError, ValueError):
        logger.log_error(
            "Couldn't properly read /proc/uptime! Skipping sleep! Please report this!"
        )


async def main():
    global crowsnest

    parser = argparse.ArgumentParser(
        prog="Crowsnest",
        description="Crowsnest - A webcam daemon for Raspberry Pi OS distributions like MainsailOS",
    )
    config = configparser.ConfigParser(
        inline_comment_prefixes="#",
        converters={
            "loglevel": utils.log_level_converter,
            "resolution": utils.resolution_converter,
        },
    )

    parser.add_argument(
        "-c", "--config", help="Path to config file", type=str, required=True
    )
    parser.add_argument(
        "-l", "--log_path", help="Path to log file", type=str, required=True
    )
    parser.add_argument(
        "-s", "--sleep_boot", help="Sleep after system boot", type=int, default=0
    )

    args = parser.parse_args()

    logger.setup_logging(args.log_path)

    check_uptime_and_sleep(args.sleep_boot)

    logging_helper.log_initial()

    initial_parse_config(args.config)

    if crowsnest is None:
        logger.log_error("Something went terribly wrong!")
        exit(1)

    if crowsnest.parameters["delete_log"]:
        logger.logger.handlers.clear()
        logger.setup_logging(args.log_path, "w")
        logging_helper.log_initial()

    logger.set_log_level(crowsnest.parameters["log_level"])

    logging_helper.log_host_info()
    logging_helper.log_streamer()
    logging_helper.log_config(args.config)
    logging_helper.log_cams()

    task1 = asyncio.create_task(start_sections())
    await asyncio.sleep(0)
    task2 = asyncio.create_task(watchdog.run_watchdog())

    await task1
    if task2:
        task2.cancel()
