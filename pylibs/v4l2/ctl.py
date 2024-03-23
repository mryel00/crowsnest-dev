"""
Python implementation of v4l2-ctl
"""

import os
import copy

from pylibs.v4l2 import raw, constants, utils

dev_ctls: dict[str, dict[str, dict[str, (raw.v4l2_ext_control, str)]]] = {}

def parse_qc(fd: int, qc: raw.v4l2_query_ext_ctrl) -> dict:
    """
    Parses the query control to an easy to use dictionary
    """
    if qc.type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
        return {}
    controls = {}
    controls['type'] = utils.v4l2_ctrl_type_to_string(qc.type)
    if qc.type in (constants.V4L2_CTRL_TYPE_INTEGER, constants.V4L2_CTRL_TYPE_MENU):
        controls['min'] = qc.minimum
        controls['max'] = qc.maximum
    if qc.type == constants.V4L2_CTRL_TYPE_INTEGER:
        controls['step'] = qc.step
    if qc.type in (
        constants.V4L2_CTRL_TYPE_INTEGER,
        constants.V4L2_CTRL_TYPE_MENU,
        constants.V4L2_CTRL_TYPE_INTEGER_MENU,
        constants.V4L2_CTRL_TYPE_BOOLEAN
    ):
        controls['default'] = qc.default_value
    if qc.flags:
        controls['flags'] = utils.ctrlflags2str(qc.flags)
    if qc.type in (constants.V4L2_CTRL_TYPE_MENU, constants.V4L2_CTRL_TYPE_INTEGER_MENU):
        controls['menu'] = {}
        for menu in utils.ioctl_iter(
            fd,
            raw.VIDIOC_QUERYMENU,
            raw.v4l2_querymenu(id=qc.id), qc.minimum, qc.maximum + 1, qc.step, True
        ):
            if qc.type == constants.V4L2_CTRL_TYPE_MENU:
                controls['menu'][menu.index] = menu.name.decode()
            else:
                controls['menu'][menu.index] = menu.value
    return controls

def init_device(device_path: str) -> None:
    """
    Initialize a given device
    """
    fd = os.open(device_path, os.O_RDWR)
    next_fl = constants.V4L2_CTRL_FLAG_NEXT_CTRL | constants.V4L2_CTRL_FLAG_NEXT_COMPOUND
    qctrl = raw.v4l2_query_ext_ctrl(id=next_fl)
    dev_ctls[device_path] = {}
    for qc in utils.ioctl_iter(fd, raw.VIDIOC_QUERY_EXT_CTRL, qctrl):
        if qc.type == constants.V4L2_CTRL_TYPE_CTRL_CLASS:
            name = qc.name.decode()
        else:
            name = utils.name2var(qc.name.decode())
        dev_ctls[device_path][name] = {}
        dev_ctls[device_path][name]['qc'] = copy.deepcopy(qc)
        dev_ctls[device_path][name]['values'] = parse_qc(fd, qc)
        # print_qctrl(fd, qc)
        qc.id |= next_fl
    # print(qctrls)
    os.close(fd)

def get_dev_ctl(device_path: str):
    if device_path not in dev_ctls:
        init_device(device_path)
    return dev_ctls[device_path]

def get_dev_ctl_parsed_dict(device_path: str) -> dict:
    if device_path not in dev_ctls:
        init_device(device_path)
    return utils.ctl_to_parsed_dict(dev_ctls[device_path])

def get_dev_path_by_name(name: str) -> str:
    """
    Get the device path by its name
    """
    prefix = 'video'
    for dev in os.listdir('/dev'):
        if dev.startswith(prefix) and dev[len(prefix):].isdigit():
            path = f'/dev/{dev}'
            if get_camera_capabilities(path)['card'].contains(name):
                return path
    return ''

def get_camera_capabilities(device_path: str) -> dict:
    """
    Get the capabilities of a given device
    """
    fd = os.open(device_path, os.O_RDWR)
    cap = raw.v4l2_capability()
    utils.ioctl_safe(fd, raw.VIDIOC_QUERYCAP, cap)
    cap_dict = {}
    cap_dict['driver'] = cap.driver.decode()
    cap_dict['card'] = cap.card.decode()
    cap_dict['bus'] = cap.bus_info.decode()
    cap_dict['version'] = cap.version
    cap_dict['capabilities'] = cap.capabilities
    os.close(fd)
    return cap_dict

def get_control_cur_value(device_path: str, control: str) -> int:
    """
    Get the current value of a control of a given device
    """
    fd = os.open(device_path, os.O_RDWR)
    ctrl = raw.v4l2_control()
    qc: raw.v4l2_query_ext_ctrl = dev_ctls[device_path][utils.name2var(control)]['qc']
    ctrl.id = qc.id
    utils.ioctl_safe(fd, raw.VIDIOC_G_CTRL, ctrl)
    os.close(fd)
    return ctrl.value

def set_control(device_path: str, control: str, value: int) -> None:
    """
    Set the value of a control of a given device
    """
    fd = os.open(device_path, os.O_RDWR)
    ctrl = raw.v4l2_control()
    qc: raw.v4l2_query_ext_ctrl = dev_ctls[device_path][control]['qc']
    ctrl.id = qc.id
    ctrl.value = value
    utils.ioctl_safe(fd, raw.VIDIOC_S_CTRL, ctrl)
    os.close(fd)

def get_formats(device_path: str) -> list:
    """
    Get the available formats of a given device
    """
    fd = os.open(device_path, os.O_RDWR)
    fmt = raw.v4l2_fmtdesc()
    frmsize = raw.v4l2_frmsizeenum()
    frmival = raw.v4l2_frmivalenum()
    fmt.index = 0
    fmt.type = constants.V4L2_BUF_TYPE_VIDEO_CAPTURE
    formats = {}
    for fmt in utils.ioctl_iter(fd, raw.VIDIOC_ENUM_FMT, fmt):
        str = f"[{fmt.index}]: '{utils.fcc2s(fmt.pixelformat)}' ({fmt.description.decode()}"
        if fmt.flags:
            str += f", {utils.fmtflags2str(fmt.flags)}"
        str += ')'
        formats[str] = {}
        frmsize.pixel_format = fmt.pixelformat
        for size in utils.ioctl_iter(fd, raw.VIDIOC_ENUM_FRAMESIZES, frmsize):
            size_str = utils.frmsize_to_str(size)
            formats[str][size_str] = []
            frmival.pixel_format = fmt.pixelformat
            frmival.width = frmsize.discrete.width
            frmival.height = frmsize.discrete.height
            for interval in utils.ioctl_iter(fd, raw.VIDIOC_ENUM_FRAMEINTERVALS, frmival):
                formats[str][size_str].append(utils.frmival_to_str(interval))
    os.close(fd)
    return formats
