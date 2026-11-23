TARGET := iphone:clang:6.1:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = GIFReader
GIFReader_FILES = main.m GIFReaderAppDelegate.m BrowserViewController.m GIFViewController.m
GIFReader_FRAMEWORKS = UIKit Foundation ImageIO CoreGraphics
GIFReader_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall -9 SpringBoard"
