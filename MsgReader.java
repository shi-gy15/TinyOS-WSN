/*									tab:4
 * Copyright (c) 2000-2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/* Authors:	Phil Levis <pal@cs.berkeley.edu>
 * Date:        December 1 2005
 * Desc:        Generic Message reader
 *               
 */

/**
 * @author Phil Levis <pal@cs.berkeley.edu>
 */


package net.tinyos.tools;

import java.util.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.util.regex.*;

public class MsgReader implements net.tinyos.message.MessageListener {

  private MoteIF moteIF;
  private BufferedWriter fout;
  private String[] patterns;
  private Pattern[] regs;
  
  public String wrapper(String raw, int index) {
      
      switch(index) {
      case 0: // "nodeid"
      case 1: // "seqno"
          return "" + Integer.parseInt(raw, 16) + " ";
      case 2: // temperature
          return String.format("%.2f", (Integer.parseInt(raw, 16) * 0.01 - 40.1)) + "C ";
      case 3: // humidity
      case 4: // radiation
          return raw + " ";
      case 5: // time
          return "" + Integer.parseInt(raw, 16);
      }
      return raw;
  }

  public void writeMessage(Message msg) throws Exception{
      String str = msg.toString();
      System.out.println(str);
      Matcher m;
      for (int i = 0; i < regs.length; i++) {
          m = regs[i].matcher(str);
          if (m.find()) {
              //fout.write("" + m.group(1) + " ");
              fout.write(wrapper(m.group(1), i));
          }
      }
      fout.newLine();
      fout.flush();
  }

  public void compileRegex() {
      patterns = new String[]{
          "nodeId",
          "index",
          "temperature",
          "humidity",
          "radiation",
          "currentTime"
      };
      regs = new Pattern[patterns.length];
      for (int i = 0; i < regs.length; i++) {
          regs[i] = Pattern.compile(patterns[i] + "=0x(\\d+)");
      }
  }



  public MsgReader(String source) throws Exception {
    if (source != null) {
      moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
    }
    else {
      moteIF = new MoteIF(BuildSource.makePhoenix(PrintStreamMessenger.err));
    }

    //.
    fout = new BufferedWriter(new FileWriter("result.txt"));
    compileRegex();
  }

  public void start() {
  }

  
  
  public void messageReceived(int to, Message message) {
    long t = System.currentTimeMillis();
    //    Date d = new Date(t);
    //System.out.print("" + t + ": ");
    //System.out.println(message);
    try {
      writeMessage(message);
    } catch(Exception e) {
      
    }
  }

  
  private static void usage() {
    System.err.println("usage: MsgReader [-comm <source>] message-class [message-class ...]");
  }

  private void addMsgType(Message msg) {
    moteIF.registerListener(msg, this);
  }
  
  public static void main(String[] args) throws Exception {
    String source = null;
    Vector v = new Vector();
    if (args.length > 0) {
      for (int i = 0; i < args.length; i++) {
	    if (args[i].equals("-comm")) {
	        source = args[++i];
	    }
        else {
            String className = args[i];
            try {
                Class c = Class.forName(className);
                Object packet = c.newInstance();
                Message msg = (Message)packet;
                if (msg.amType() < 0) {
                    System.err.println(className + " does not have an AM type - ignored");
                }
                else {
                    v.addElement(msg);
                }
            }
            catch (Exception e) {
                System.err.println(e);
            }
        }
      }
    }
    else if (args.length != 0) {
        usage();
        System.exit(1);
    }

    MsgReader mr = new MsgReader(source);
    Enumeration msgs = v.elements();
    while (msgs.hasMoreElements()) {
      Message m = (Message)msgs.nextElement();
      mr.addMsgType(m);
    }
    mr.start();
  }


}
