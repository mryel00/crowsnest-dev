#!/usr/bin/python3

V4L2_CTRL_MAX_DIMS                  = 4

V4L2_CTRL_TYPE_INTEGER              = 1
V4L2_CTRL_TYPE_BOOLEAN              = 2
V4L2_CTRL_TYPE_MENU	                = 3
V4L2_CTRL_TYPE_BUTTON               = 4
V4L2_CTRL_TYPE_INTEGER64            = 5
V4L2_CTRL_TYPE_CTRL_CLASS           = 6
V4L2_CTRL_TYPE_STRING               = 7
V4L2_CTRL_TYPE_BITMASK              = 8
V4L2_CTRL_TYPE_INTEGER_MENU         = 9

V4L2_BUF_TYPE_VIDEO_CAPTURE         = 1
V4L2_BUF_TYPE_VIDEO_OUTPUT          = 2
V4L2_BUF_TYPE_VIDEO_OVERLAY         = 3
V4L2_BUF_TYPE_VBI_CAPTURE           = 4
V4L2_BUF_TYPE_VBI_OUTPUT            = 5
V4L2_BUF_TYPE_SLICED_VBI_CAPTURE    = 6
V4L2_BUF_TYPE_SLICED_VBI_OUTPUT     = 7
V4L2_BUF_TYPE_VIDEO_OUTPUT_OVERLAY  = 8
V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE  = 9
V4L2_BUF_TYPE_VIDEO_OUTPUT_MPLANE   = 10
V4L2_BUF_TYPE_SDR_CAPTURE           = 11
V4L2_BUF_TYPE_SDR_OUTPUT            = 12
V4L2_BUF_TYPE_META_CAPTURE          = 13
V4L2_BUF_TYPE_META_OUTPUT	        = 14

V4L2_FMT_FLAG_COMPRESSED            = 0x0001
V4L2_FMT_FLAG_EMULATED              = 0x0002
V4L2_FMT_FLAG_CONTINUOUS_BYTESTREAM = 0x0004
V4L2_FMT_FLAG_DYN_RESOLUTION        = 0x0008
V4L2_FMT_FLAG_ENC_CAP_FRAME_INTERVAL = 0x0010
V4L2_FMT_FLAG_CSC_COLORSPACE        = 0x0020
V4L2_FMT_FLAG_CSC_XFER_FUNC         = 0x0040
V4L2_FMT_FLAG_CSC_YCBCR_ENC         = 0x0080
V4L2_FMT_FLAG_CSC_HSV_ENC           = V4L2_FMT_FLAG_CSC_YCBCR_ENC
V4L2_FMT_FLAG_CSC_QUANTIZATION      = 0x0100

V4L2_FRMSIZE_TYPE_DISCRETE          = 1
V4L2_FRMSIZE_TYPE_CONTINUOUS        = 2
V4L2_FRMSIZE_TYPE_STEPWISE          = 3

V4L2_FRMIVAL_TYPE_DISCRETE          = 1
V4L2_FRMIVAL_TYPE_CONTINUOUS        = 2
V4L2_FRMIVAL_TYPE_STEPWISE          = 3

# Control flags
V4L2_CTRL_FLAG_DISABLED             = 0x0001
V4L2_CTRL_FLAG_GRABBED              = 0x0002
V4L2_CTRL_FLAG_READ_ONLY            = 0x0004
V4L2_CTRL_FLAG_UPDATE               = 0x0008
V4L2_CTRL_FLAG_INACTIVE             = 0x0010
V4L2_CTRL_FLAG_SLIDER               = 0x0020
V4L2_CTRL_FLAG_WRITE_ONLY           = 0x0040
V4L2_CTRL_FLAG_VOLATILE             = 0x0080
V4L2_CTRL_FLAG_HAS_PAYLOAD          = 0x0100
V4L2_CTRL_FLAG_EXECUTE_ON_WRITE     = 0x0200
V4L2_CTRL_FLAG_MODIFY_LAYOUT        = 0x0400
V4L2_CTRL_FLAG_DYNAMIC_ARRAY        = 0x0800
# Query flags, to be ORed with the control ID
V4L2_CTRL_FLAG_NEXT_CTRL            = 0x80000000
V4L2_CTRL_FLAG_NEXT_COMPOUND        = 0x40000000
# User-class control IDs defined by V4L2
V4L2_CID_MAX_CTRLS                  = 1024
# IDs reserved for driver specific controls
V4L2_CID_PRIVATE_BASE               = 0x08000000
