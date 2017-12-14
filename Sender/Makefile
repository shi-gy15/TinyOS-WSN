COMPONENT=SenderAppC
BUILD_EXTRA_DEPS += Sender.class
CLEAN_EXTRA = *.class Message.java
# CFLAGS += -I$(TOSDIR)/lib/T2Hack
Receiver.class: $(wildcard *.java) Message.java
	javac -target 1.4 -source 1.4 *.java
Message.java:
	mig java -target=null -java-classname=Message Message.h SenseMsg -o $(@)
include $(MAKERULES)