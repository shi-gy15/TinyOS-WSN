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

import javax.swing.*;

import java.lang.Math;

import java.util.List;

import java.awt.*;

class MsgPacket {
    static int MAX_ITEMS = 40;
    private static String[] patterns = {
        "nodeId",
        "index",
        "temperature",
        "humidity",
        "radiation",
        "currentTime"
    };
    private static Pattern[] regs;
    private static BufferedWriter fout;
    static List<MsgPacket> lis;
    private static boolean hasInited = false;

    int[] datas;
    String raw;

    private MsgPacket() {

    }

    static MsgPacket form(String src) {
        MsgPacket packet = new MsgPacket();
        packet.raw = src;
        Matcher m;
        packet.datas = new int[regs.length];
        for (int i = 0; i < regs.length; i++) {
            m = regs[i].matcher(src);
            if (m.find()) {
                packet.datas[i] = hex2int(m.group(1));
            }
        }
        lis.add(packet);
        if (lis.size() > MAX_ITEMS) {
            lis.remove(0);
        }
        return packet;
    }

    void display() throws Exception{
        for (int i = 0; i < this.datas.length; i++) {
            fout.write(wrapper(datas[i], i));
        }
        fout.newLine();
        fout.flush();
    }

    static void init() throws Exception{
        if (hasInited) {
            return;
        }
        fout = new BufferedWriter(new FileWriter("result.txt"));
        compileRegex();
        lis = new ArrayList<>();
        hasInited = true;
    }

    private static void compileRegex() {
        String msgFormat = "=0x([0-9a-fA-F]+)";
        regs = new Pattern[patterns.length];
        for (int i = 0; i < regs.length; i++) {
            regs[i] = Pattern.compile(patterns[i] + msgFormat);
        }
    }

    private static int hex2int(String raw) {
        return Integer.parseInt(raw, 16);
    }

    private static String wrapper(int val, int index) {

        switch(index) {
            case 0: // "nodeid"
            case 1: // "index"
                return "" + val + " ";
            case 2: // temperature
                return String.format("%.2f", (val * 0.01 - 40.1)) + "C ";
            case 3: // humidity
            case 4: // radiation
                return val + " ";
            case 5: // currentTime
            default:
                return "" + val;
        }
    }
}

class Const {
    // window' size
    static int WND_WIDTH = 1000;
    static int WND_HEIGHT = 600;

    // padding
    static int PADDING_TOP = 30;
    static int PADDING_BOTTOM = 80;
    static int PADDING_LEFT = 80;
    static int PADDING_RIGHT = 100;

    // origin
    static int ORIGIN_X = PADDING_LEFT;
    static int ORIGIN_Y = WND_HEIGHT - PADDING_BOTTOM;

    // end of x axis
    static int AXIS_X_X = WND_WIDTH - PADDING_RIGHT;
    static int AXIS_X_Y = ORIGIN_Y;

    // end of y axis
    static int AXIS_Y_X = ORIGIN_X;
    static int AXIS_Y_Y = PADDING_TOP;

    // axis color
    static Color AXIS_COLOR = new Color(0, 0, 0);

    // point color
    static Color POINT_TEMPERATURE_COLOR = new Color(192, 64, 64);
    static Color POINT_HUMIDITY_COLOR = new Color(64, 192, 64);
    static Color POINT_RADIATION_COLOR = new Color(64, 64, 192);

    // limit of temperature
    static int TEMPERATURE_MAX = 1000;
    static int TEMPERATURE_MIN = 600;

    // limit of humidity
    static int HUMIDITY_MAX = 1000;
    static int HUMIDITY_MIN = 600;

    // limit of RADIATION
    static int RADIATION_MAX = 1000;
    static int RADIATION_MIN = 600;

    // max point number
    static int MAX_POINT_NUM = MsgPacket.MAX_ITEMS;

    // point radius
    static int POINT_RADIUS = 3;

    // stroke width
    static float STROKE_WIDTH = 2.0f;

    // text color
    static Color TEXT_COLOR = new Color(32, 32, 32);

    // font size
    static int FONT_SIZE = 20;

    // text font
    static Font TEXT_FONT = new Font("Constantia", Font.PLAIN, FONT_SIZE);

    // legend position
    static int LEGEND_X = 800;
    static int LEGEND_TEMPERATURE_Y = 100;
    static int LEGEND_HUMIDITY_Y = 150;
    static int LEGEND_RADIATION_Y = 200;
    static int LEGEND_RECT_WIDTH = 40;
    static int LEGEND_RECT_HEIGHT = 20;

    // coordinate text font
    static int COORDINATE_FONT_SIZE = 12;
    static Font COORDINATE_FONT = new Font("Consolas", Font.PLAIN, COORDINATE_FONT_SIZE);
}

class Point {
    int x, y;
    Point(int x, int y) {
        this.x = x;
        this.y = y;
    }
    Point(Point src) {
        this.x = src.x;
        this.y = src.y;
    }
    Point() {

    }
}

class MyCanvas extends JPanel {
    private static Point origin = new Point(Const.ORIGIN_X, Const.ORIGIN_Y);
    private static Point axisX = new Point(Const.AXIS_X_X, Const.AXIS_X_Y);
    private static Point axisY = new Point(Const.AXIS_Y_X, Const.AXIS_Y_Y);

    static Point calc(Character type, int val, int index) {
        // auto cast to integer
        Point res = new Point();
        res.x = origin.x + (axisX.x - origin.x) * index / Const.MAX_POINT_NUM;
        switch (type) {
            // temperature
            case 't':
                res.y = origin.y + (val - Const.TEMPERATURE_MIN) * (axisY.y - origin.y)
                        / (Const.TEMPERATURE_MAX - Const.TEMPERATURE_MIN);
                break;
            // humidity
            case 'h':
                res.y = origin.y + (val - Const.HUMIDITY_MIN) * (axisY.y - origin.y)
                        / (Const.HUMIDITY_MAX - Const.HUMIDITY_MIN);
                break;
            // radiation
            case 'r':
                res.y = origin.y + (val - Const.RADIATION_MIN) * (axisY.y - origin.y)
                        / (Const.RADIATION_MAX - Const.RADIATION_MIN);
                break;
            // coordinate x
            case 'x':
                res.y = origin.y;
                break;
            default:
                System.out.println("error in parsing [" + type + "]");
                res.y = origin.y;
                break;
        }
        return res;
    }

    public void paintComponent(Graphics g) {
        Graphics2D g2D = (Graphics2D) g;

        // anti-aliasing
        g2D.setRenderingHint(RenderingHints.KEY_ANTIALIASING,RenderingHints.VALUE_ANTIALIAS_ON);

        // stroke
        g2D.setStroke(new BasicStroke(Const.STROKE_WIDTH));

        super.paintComponent(g);

        paintAxis(g2D);
        paintLegend(g2D);
        paintCoordinate(g2D);

        paintSingle(g2D, 't');
        paintSingle(g2D, 'h');
        paintSingle(g2D, 'r');

    }

    private void paintLegend(Graphics2D g) {
        g.setColor(Const.POINT_TEMPERATURE_COLOR);
        g.fillRect(Const.LEGEND_X, Const.LEGEND_TEMPERATURE_Y, Const.LEGEND_RECT_WIDTH, Const.LEGEND_RECT_HEIGHT);
        g.setColor(Const.TEXT_COLOR);
        g.drawChars("temperature".toCharArray(), 0, 11, Const.LEGEND_X + Const.LEGEND_RECT_WIDTH, Const.LEGEND_TEMPERATURE_Y + Const.LEGEND_RECT_HEIGHT);

        g.setColor(Const.POINT_HUMIDITY_COLOR);
        g.fillRect(Const.LEGEND_X, Const.LEGEND_HUMIDITY_Y, Const.LEGEND_RECT_WIDTH, Const.LEGEND_RECT_HEIGHT);
        g.setColor(Const.TEXT_COLOR);
        g.drawChars("humidity".toCharArray(), 0, 8, Const.LEGEND_X + Const.LEGEND_RECT_WIDTH, Const.LEGEND_HUMIDITY_Y + Const.LEGEND_RECT_HEIGHT);

        g.setColor(Const.POINT_RADIATION_COLOR);
        g.fillRect(Const.LEGEND_X, Const.LEGEND_RADIATION_Y, Const.LEGEND_RECT_WIDTH, Const.LEGEND_RECT_HEIGHT);
        g.setColor(Const.TEXT_COLOR);
        g.drawChars("radiation".toCharArray(), 0, 9, Const.LEGEND_X + Const.LEGEND_RECT_WIDTH, Const.LEGEND_RADIATION_Y + Const.LEGEND_RECT_HEIGHT);
    }


    private void paintAxis(Graphics2D g) {
        g.setColor(Const.AXIS_COLOR);
        g.drawLine(origin.x, origin.y, axisX.x, axisX.y);
        g.drawLine(origin.x, origin.y, axisY.x, axisY.y);

        g.setColor(Const.TEXT_COLOR);
        g.setFont(Const.TEXT_FONT);
        g.drawChars("time".toCharArray(), 0, 4, axisX.x, axisX.y + Const.FONT_SIZE / 2);
        g.drawChars("value".toCharArray(), 0, 5, axisY.x - Const.FONT_SIZE, axisY.y - Const.FONT_SIZE / 2);
    }

    private void paintSingle(Graphics2D g, Character t) {
        int pos = 0;
        switch(t) {
            case 't':
                g.setColor(Const.POINT_TEMPERATURE_COLOR);
                pos = 2;
                break;
            case 'h':
                g.setColor(Const.POINT_HUMIDITY_COLOR);
                pos = 3;
                break;
            case 'r':
                g.setColor(Const.POINT_RADIATION_COLOR);
                pos = 4;
                break;
            default:
                System.out.println("error in parsing [" + t + "]");
                g.setColor(Const.POINT_TEMPERATURE_COLOR);
                break;
        }

        int length = Math.min(MsgPacket.lis.size(), Const.MAX_POINT_NUM);
        Point lastPoint = null;

        for (int i = 0; i < length; i++) {
            Point point = calc(t, MsgPacket.lis.get(i).datas[pos], i);
            g.fillOval(point.x - Const.POINT_RADIUS, point.y - Const.POINT_RADIUS, 2 * Const.POINT_RADIUS, 2 * Const.POINT_RADIUS);
            if (lastPoint != null) {
                g.drawLine(lastPoint.x, lastPoint.y, point.x, point.y);
            }
            lastPoint = point;
        }

    }

    private void paintCoordinate(Graphics2D g) {
        g.setFont(Const.COORDINATE_FONT);
        int length = Math.min(MsgPacket.lis.size(), Const.MAX_POINT_NUM);
        for (int i = 0; i < Const.MAX_POINT_NUM; i++) {
            // when in coordinate mode, 'val' param is useless
            Point point = calc('x', 0, i);
            g.drawChars(("" + i).toCharArray(), 0, ("" + i).length(), point.x, point.y + Const.COORDINATE_FONT_SIZE);
        }
    }
}

// singleton
class SwingChart {
    private JFrame frame;
    private static SwingChart test = null;

    static synchronized SwingChart getInstance() {
        if (test == null) {
            test = new SwingChart();
        }
        return test;
    }

    public static void main(String[] args) {
        getInstance();
    }


    private SwingChart() {
        try {
            MsgPacket.init();
        } catch (Exception e){

        }

        createAndShowGUI();
    }

    void update() {
        frame.repaint();
    }

    private void createAndShowGUI() {

        // create window
        frame = new JFrame("WSN data chart");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);

        frame.setBounds(0, 0, Const.WND_WIDTH, Const.WND_HEIGHT);
        frame.setResizable(true);

        MyCanvas myc = new MyCanvas();

        frame.add(myc);

        frame.setVisible(true);
    }
}




public class MyMsgReader implements net.tinyos.message.MessageListener {

  private MoteIF moteIF;
  

  public MyMsgReader(String source) throws Exception {
    if (source != null) {
      moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
    }
    else {
      moteIF = new MoteIF(BuildSource.makePhoenix(PrintStreamMessenger.err));
    }

    SwingChart.getInstance();
  }

  public void start() {
  }

  
  
  public void messageReceived(int to, Message message) {
    long t = System.currentTimeMillis();
    //    Date d = new Date(t);
    //System.out.print("" + t + ": ");
    //System.out.println(message);
    try {
        String str = message.toString();
        System.out.println(str);
        MsgPacket.form(str).display();
        SwingChart.getInstance().update();
    } catch(Exception e) {
      
    }
  }

  
  private static void usage() {
    System.err.println("usage: MyMsgReader [-comm <source>] message-class [message-class ...]");
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

    MyMsgReader mr = new MyMsgReader(source);
    Enumeration msgs = v.elements();
    while (msgs.hasMoreElements()) {
      Message m = (Message)msgs.nextElement();
      mr.addMsgType(m);
    }
    mr.start();
  }


}
