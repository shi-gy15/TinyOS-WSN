COMPONENT=ReceiverAppC
BUILD_EXTRA_DEPS += Receiver.class
CLEAN_EXTRA = *.class Message.java WorkMsg.java
# CFLAGS += -I$(TOSDIR)/lib/T2Hack
Receiver.class: $(wildcard *.java) Message.java WorkMsg.java
	javac -target 1.4 -source 1.4 *.java
Message.java:
	mig java -target=null -java-classname=Message Message.h SenseMsg -o $(@)
WorkMsg.java:
	mig java -target=null -java-classname=WorkMsg Message.h WorkMsg -o $(@)
include $(MAKERULES)