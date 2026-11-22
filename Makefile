TARGET := iphone:clang:6.1:6.0
ARCHS := armv7

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Giffy
Giffy_FILES = main.m GiffyAppDelegate.m BrowserViewController.m GIFViewController.m
Giffy_FRAMEWORKS = UIKit Foundation ImageIO CoreGraphics
Giffy_INSTALL_PATH = /Applications

include $(THEOS_MAKE_PATH)/application.mk

after-install::
	install.exec "killall -9 SpringBoard"
