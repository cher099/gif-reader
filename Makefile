TARGET := iphone:clang:6.1:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PhotosGIF
PhotosGIF_FILES = Tweak.xm
PhotosGIF_FRAMEWORKS = UIKit Foundation ImageIO CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
