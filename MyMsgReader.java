
package net.tinyos.tools;

import java.util.*;
import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.regex.*;
import java.lang.reflect.Method;
import java.text.SimpleDateFormat;
import javax.swing.*;
import java.lang.Math;
import java.util.List;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

class Const {
    // window' size
    static final int WND_WIDTH = 1000;
    static final int WND_HEIGHT = 600;

    // padding
    static final int PADDING_TOP = 30;
    static final int PADDING_BOTTOM = 80;
    static final int PADDING_LEFT = 60;
    static final int PADDING_RIGHT = 100;

    // origin
    static final int ORIGIN_X = PADDING_LEFT;
    static final int ORIGIN_Y = WND_HEIGHT - PADDING_BOTTOM;

    // end of x axis
    static final int AXIS_X_X = WND_WIDTH - PADDING_RIGHT;
    static final int AXIS_X_Y = ORIGIN_Y;

    // end of y axis
    static final int AXIS_Y_X = ORIGIN_X;
    static final int AXIS_Y_Y = PADDING_TOP;

    // axis color
    static final Color AXIS_COLOR = new Color(0, 0, 0);

    // point color
    static final Color POINT_TEMPERATURE_COLOR = new Color(192, 64, 64);
    static final Color POINT_HUMIDITY_COLOR = new Color(64, 192, 64);
    static final Color POINT_RADIATION_COLOR = new Color(64, 64, 192);

    // limit of temperature
    static int TEMPERATURE_MAX = 6510;
    static int TEMPERATURE_MIN = 6470;

    // limit of humidity
    static int HUMIDITY_MAX = 800;
    static int HUMIDITY_MIN = 760;

    // limit of radiation
    static int RADIATION_MAX = 200;
    static int RADIATION_MIN = 0;

    // max point number
    static final int MAX_POINT_NUM = MsgPacket.MAX_ITEMS;

    // point radius
    static final int POINT_RADIUS = 3;

    // stroke width
    static final float STROKE_WIDTH = 2.0f;

    // text color
    static final Color TEXT_COLOR = new Color(32, 32, 32);

    // font size
    static final int FONT_SIZE = 20;

    // text font
    static final Font TEXT_FONT = new Font("Constantia", Font.PLAIN, FONT_SIZE);

    // legend position
    static final int LEGEND_X = 800;
    static final int LEGEND_TEMPERATURE_Y = 100;
    static final int LEGEND_HUMIDITY_Y = 150;
    static final int LEGEND_RADIATION_Y = 200;
    static final int LEGEND_RECT_WIDTH = 40;
    static final int LEGEND_RECT_HEIGHT = 20;

    // coordinate text font
    static final int COORDINATE_FONT_SIZE = 12;
    static final Font COORDINATE_FONT = new Font("Consolas", Font.PLAIN, COORDINATE_FONT_SIZE);

    // coordinate interval
    static final int COORDINATE_INTEGRAL = 8;

    // node id range
    static final int NODE_ID_RANGE = 2;

    // button size
    static final int BUTTON_WIDTH = 80;
    static final int BUTTON_HEIGHT = 50;

    // button position
    static final int BUTTON_X = 300;
    static final int BUTTON_Y = 0;

    // frequency
    static final int SAMPLING_FREQUENCY = 500;

    // frequency button
    static final int FREQUENCY_BUTTON_X = 800;
    static final int FREQUENCY_BOTTON_Y = 0;

    // frequency input field
    static final int FREQUENCY_INPUT_X = 500;
    static final int FREQUENCY_INPUT_Y = 0;
    static final int FREQUENCY_WIDTH = 100;
    static final int FREQUENCY_HEIGHT = 80;

    // single chart
    static final int MAX_POINT_SINGLE = 40;

    // y axis element
    static final int ELEM_NUM_Y = 5;
}

class MsgPacket {
    static int MAX_ITEMS = 80;
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
    static long startTime = 0;
    static SimpleDateFormat timeForm = new SimpleDateFormat("HH:mm:ss.SSS");

    int[] datas;

    static String calcTime(int stamp) {
        return timeForm.format(stamp);
    }

    private MsgPacket() {

    }

    static MsgPacket form(String src) {
        MsgPacket packet = new MsgPacket();
        
        Matcher m;
        packet.datas = new int[regs.length];
        for (int i = 0; i < regs.length; i++) {
            m = regs[i].matcher(src);
            if (m.find()) {
                packet.datas[i] = hex2int(m.group(1));
            }
        }
        packet.datas[5] += startTime;
        lis.add(packet);
        if (lis.size() >= MAX_ITEMS) {
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
                return String.format("%.2f", val / 25.0 - 28.0 * val * val / 10000000.0 - 4) + "rh ";
            case 4: // radiation
                return val + "lx ";
            case 5: // currentTime
                return calcTime(val);
            default:
                return "" + val;
        }
    }

    int getValue(String key) {
        for (int i = 0; i < patterns.length; i++) {
            if (patterns[i].equals(key)) {
                return this.datas[i];
            }
        }
        System.out.println("error in parsing key [" + key + "]");
        return 0;
    }

    void setValue(String key, int val) {
        for (int i = 0; i < patterns.length; i++) {
            if (patterns[i].equals(key)) {
                this.datas[i] = val;
                return;
            }
        }
        System.out.println("error in parsing key [" + key + "]");
    }
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

    // limit of temperature
    static int TEMPERATURE_MAX = Const.TEMPERATURE_MAX;
    static int TEMPERATURE_MIN = Const.TEMPERATURE_MIN;

    // limit of humidity
    static int HUMIDITY_MAX = Const.HUMIDITY_MAX;
    static int HUMIDITY_MIN = Const.HUMIDITY_MIN;

    // limit of radiation
    static int RADIATION_MAX = Const.RADIATION_MAX;
    static int RADIATION_MIN = Const.RADIATION_MIN;

    

    int nodeIDSwitch;

    MyCanvas() {
        this.nodeIDSwitch = 1;
        
    }

    static Point calc(Character type, int val, int index) {
        // auto cast to integer
        Point res = new Point();
        res.x = origin.x + (axisX.x - origin.x) * index / Const.MAX_POINT_SINGLE;
        switch (type) {
            // temperature
            case 't':
                res.y = origin.y + (val - TEMPERATURE_MIN) * (axisY.y - origin.y)
                        / (TEMPERATURE_MAX - TEMPERATURE_MIN);
                break;
            // humidity
            case 'h':
                res.y = origin.y + (val - HUMIDITY_MIN) * (axisY.y - origin.y)
                        / (HUMIDITY_MAX - HUMIDITY_MIN);
                break;
            // radiation
            case 'r':
                res.y = origin.y + (val - RADIATION_MIN) * (axisY.y - origin.y)
                        / (RADIATION_MAX - RADIATION_MIN);
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

    public static void initLimit(MsgPacket packet) {
        TEMPERATURE_MAX = packet.getValue("temperature") + 50;
        TEMPERATURE_MIN = TEMPERATURE_MAX - 100;
        HUMIDITY_MAX = packet.getValue("humidity") + 20;
        HUMIDITY_MIN = HUMIDITY_MAX - 40;
        RADIATION_MAX = packet.getValue("radiation") + 5;
        RADIATION_MIN = 0;
    }

    public void paintComponent(Graphics g) {
        Graphics2D g2D = (Graphics2D) g;

        // anti-aliasing
        g2D.setRenderingHint(RenderingHints.KEY_ANTIALIASING,RenderingHints.VALUE_ANTIALIAS_ON);
        // stroke
        g2D.setStroke(new BasicStroke(Const.STROKE_WIDTH));
        super.paintComponent(g);
        calcLimit();
        paintYValue(g2D);
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

    private void paintYValue(Graphics2D g) {
        g.setFont(Const.COORDINATE_FONT);
        int x = 10;
        int y = 0;
        int temperature;
        int humidity;
        int radiation;
        for (int i = 0; i <= Const.ELEM_NUM_Y; i++) {
            y = Const.ORIGIN_Y + (Const.AXIS_Y_Y - Const.ORIGIN_Y) * i / Const.ELEM_NUM_Y;
            temperature = (TEMPERATURE_MIN + (TEMPERATURE_MAX - TEMPERATURE_MIN) * i / Const.ELEM_NUM_Y);
            humidity = (HUMIDITY_MIN + (HUMIDITY_MAX - HUMIDITY_MIN) * i / Const.ELEM_NUM_Y);
            radiation = (RADIATION_MIN + (RADIATION_MAX - RADIATION_MIN) * i / Const.ELEM_NUM_Y);
            
            String form;
            g.setColor(Const.POINT_TEMPERATURE_COLOR);
            form = String.format("%.2f", (temperature * 0.01 - 40.1)) + "C";
            g.drawChars(form.toCharArray(), 0, form.length(), x, y);
            g.setColor(Const.POINT_HUMIDITY_COLOR);
            form = String.format("%.1f", humidity / 25.0 - 28.0 * humidity * humidity / 10000000.0 - 4) + "rh";
            g.drawChars(form.toCharArray(), 0, form.length(), x, y + Const.COORDINATE_FONT_SIZE);
            g.setColor(Const.POINT_RADIATION_COLOR);
            form = radiation + "lx";
            g.drawChars(form.toCharArray(), 0, form.length(), x, y + 2 * Const.COORDINATE_FONT_SIZE);
        }
    }


    private void paintAxis(Graphics2D g) {
        g.setColor(Const.AXIS_COLOR);
        g.drawLine(origin.x, origin.y, axisX.x, axisX.y);
        g.drawLine(origin.x, origin.y, axisY.x, axisY.y);

        g.setColor(Const.TEXT_COLOR);
        g.setFont(Const.TEXT_FONT);
        g.drawChars("time(ms)".toCharArray(), 0, 8, axisX.x, axisX.y);
        g.drawChars("value".toCharArray(), 0, 5, axisY.x - Const.FONT_SIZE, axisY.y - Const.FONT_SIZE / 2);
    }

    private void paintSingle(Graphics2D g, Character t) {
        String key = "nodeId";
        switch(t) {
            case 't':
                g.setColor(Const.POINT_TEMPERATURE_COLOR);
                key = "temperature";
                break;
            case 'h':
                g.setColor(Const.POINT_HUMIDITY_COLOR);
                key = "humidity";
                break;
            case 'r':
                g.setColor(Const.POINT_RADIATION_COLOR);
                key = "radiation";
                break;
            default:
                System.out.println("error in parsing [" + t + "]");
                g.setColor(Const.POINT_TEMPERATURE_COLOR);
                break;
        }

        int length = MsgPacket.lis.size();
        Point lastPoint = null;
        int idCount = 0;
        MsgPacket packet;
        for (int i = 0; i < length; i++) {
            if (idCount >= Const.MAX_POINT_SINGLE) {
                break;
            }
            packet = MsgPacket.lis.get(i);
            if (packet.getValue("nodeId") == nodeIDSwitch) {
                Point point = calc(t, packet.getValue(key), idCount);
                g.fillOval(point.x - Const.POINT_RADIUS, point.y - Const.POINT_RADIUS, 2 * Const.POINT_RADIUS, 2 * Const.POINT_RADIUS);
                if (lastPoint != null) {
                    g.drawLine(lastPoint.x, lastPoint.y, point.x, point.y);
                }
                lastPoint = point;
                idCount++;
            }
        }
    }

    private void calcLimit() {
        int length = MsgPacket.lis.size();
        int idCount = 0;
        int tempVal;
        MsgPacket packet;
        // TEMPERATURE_MAX = Const.TEMPERATURE_MAX;
        // TEMPERATURE_MIN = Const.TEMPERATURE_MIN;
        // HUMIDITY_MAX = Const.HUMIDITY_MAX;
        // HUMIDITY_MIN = Const.HUMIDITY_MIN;
        // RADIATION_MAX = Const.RADIATION_MAX;
        // RADIATION_MIN = Const.RADIATION_MIN;
        for (int i = 0; i < length; i++) {
            if (idCount >= Const.MAX_POINT_SINGLE) {
                break;
            }
            packet = MsgPacket.lis.get(i);
            if (packet.getValue("nodeId") == nodeIDSwitch) {
                if (idCount == 0) {
                    TEMPERATURE_MAX = packet.getValue("temperature") + 20;
                    TEMPERATURE_MIN = TEMPERATURE_MAX - 40;
                    HUMIDITY_MAX = packet.getValue("humidity") + 20;
                    HUMIDITY_MIN = HUMIDITY_MAX - 30;
                    RADIATION_MAX = 100;
                    RADIATION_MIN = 0;
                    //setted[nodeIDSwitch - 1] = true;
                    idCount++;
                    continue;
                }
                tempVal = packet.getValue("temperature");
                if (tempVal > TEMPERATURE_MAX) {
                    TEMPERATURE_MAX = tempVal;
                } else if (tempVal < TEMPERATURE_MIN) {
                    TEMPERATURE_MIN = tempVal;
                }
                tempVal = packet.getValue("humidity");
                if (tempVal > HUMIDITY_MAX) {
                    HUMIDITY_MAX = tempVal;
                } else if (tempVal < HUMIDITY_MIN) {
                    HUMIDITY_MIN = tempVal;
                }
                tempVal = packet.getValue("radiation");
                if (tempVal > RADIATION_MAX) {
                    RADIATION_MAX = tempVal;
                } else if (tempVal < RADIATION_MIN) {
                    RADIATION_MIN = tempVal;
                }
                idCount++;
            }
            
        }
    }
    

    private void paintCoordinate(Graphics2D g) {
        g.setFont(Const.COORDINATE_FONT);
        int length = MsgPacket.lis.size();
        int idCount = 0;
        MsgPacket packet;
        for (int i = 0; i < length; i++) {
            if (idCount >= Const.MAX_POINT_SINGLE) {
                break;
            }
            packet = MsgPacket.lis.get(i);
            if (packet.getValue("nodeId") == nodeIDSwitch) {
                if (idCount % Const.COORDINATE_INTEGRAL == 0) {
                    Point point = calc('x', 0, idCount);
                    String timeinfo = MsgPacket.calcTime(packet.getValue("currentTime"));
                    g.drawChars(timeinfo.toCharArray(), 0, timeinfo.length(),
                            point.x, point.y + Const.COORDINATE_FONT_SIZE);
                }
                idCount++;
            }
        }
    }
}

// singleton
class SwingChart {
    private MyCanvas myc;
    private JFrame frame;
    private static SwingChart test = null;
    private JButton[] nodeBtns;
    private NodeBtnClickListener[] listeners;
    private JButton frequencyBtn;
    private FrequencyBtnClickListener setListener;
    private JTextField frequencyInput;
    private MyMsgReader user;

    static synchronized SwingChart getInstance() {
        if (test == null) {
            test = new SwingChart();
        }
        return test;
    }

    int getFrequency() {
        return Integer.parseInt(frequencyInput.getText());
    }

    private SwingChart() {
        try {
            MsgPacket.init();
        } catch (Exception e){

        }
        prepareGUI();
    }

    void update() {
        frame.repaint();
    }

    void setUser(MyMsgReader user) {
        this.user = user;
    }

    private void prepareGUI() {
        // create window
        frame = new JFrame("WSN data chart");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setBounds(0, 0, Const.WND_WIDTH, Const.WND_HEIGHT);
        frame.setResizable(true);
        // canvas
        myc = new MyCanvas();
        frame.add(myc);

        // show nodes
        nodeBtns = new JButton[Const.NODE_ID_RANGE];
        listeners = new NodeBtnClickListener[Const.NODE_ID_RANGE];
        for (int i = 0; i < Const.NODE_ID_RANGE; i++) {
            listeners[i] = new NodeBtnClickListener(i + 1);
            nodeBtns[i] = new JButton();
            nodeBtns[i].setBounds(Const.BUTTON_X, Const.BUTTON_Y, Const.BUTTON_WIDTH, Const.BUTTON_HEIGHT);
            nodeBtns[i].setSize(Const.BUTTON_WIDTH, Const.BUTTON_HEIGHT);
            nodeBtns[i].setHideActionText(true);
            nodeBtns[i].setText("node " + (i + 1));
            nodeBtns[i].setBorderPainted(false);
            nodeBtns[i].addActionListener(listeners[i]);
            myc.add(nodeBtns[i]);
        }

        // set frequency
        frequencyBtn = new JButton();
        frequencyBtn.setHideActionText(true);
        frequencyBtn.setText("set");
        frequencyBtn.setBounds(Const.FREQUENCY_BUTTON_X, Const.FREQUENCY_BOTTON_Y, Const.BUTTON_WIDTH, Const.BUTTON_HEIGHT);
        frequencyBtn.setBorderPainted(false);
        setListener = new FrequencyBtnClickListener();
        frequencyBtn.addActionListener(setListener);

        myc.add(frequencyBtn);

        frequencyInput = new JTextField("" + Const.SAMPLING_FREQUENCY, 6);
        frequencyInput.setBounds(Const.FREQUENCY_INPUT_X, Const.FREQUENCY_INPUT_Y, Const.FREQUENCY_WIDTH, Const.FREQUENCY_HEIGHT);
        myc.add(frequencyInput);

        frame.setVisible(true);
    }


    class NodeBtnClickListener implements ActionListener {
        int nodeId;
        NodeBtnClickListener(int i) {
            this.nodeId = i;
        }
        @Override
        public void actionPerformed(ActionEvent e) {
            myc.nodeIDSwitch = nodeId;
            update();
        }
    }

    class FrequencyBtnClickListener implements ActionListener {
        FrequencyBtnClickListener() {

        }

        @Override
        public void actionPerformed(ActionEvent e) {
            MsgPacket.startTime = System.currentTimeMillis() % 86400000;
            
	    System.out.println(MsgPacket.startTime);
            user.sendStartCommand(getFrequency());
        }
    }
}

public class MyMsgReader implements net.tinyos.message.MessageListener {

  private MoteIF moteIF;
  private static String commandClassType;
  
    // init or not
    static boolean setted = false;
  

  public MyMsgReader(String source) throws Exception {
    if (source != null) {
      moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
    }
    else {
      moteIF = new MoteIF(BuildSource.makePhoenix(PrintStreamMessenger.err));
    }

    SwingChart.getInstance().setUser(this);
  }

  public void start() {
  }

  public void sendStartCommand(int sensePeriod) {
    try {
        Class cmdType = Class.forName(commandClassType);
        Object payload = cmdType.newInstance();
    
        Method[] methods = cmdType.getMethods();
        for (Method method : methods) {
            String name = method.getName();
            if (name.equals("set_status")) {
                method.invoke(payload, 1);
            }
            if (name.equals("set_sensePeriod")) {
                method.invoke(payload, sensePeriod);
            }
            if (name.equals("set_sendPeriod")) {
                method.invoke(payload, sensePeriod * 2);
            }
            if (name.equals("set_windowSize")) {
                method.invoke(payload, 10);
            }
            this.moteIF.send(0, Message.class.cast(cmdType.cast(payload)));
        }
    } catch(Exception e) {
        e.printStackTrace();
    }
  }
  
  
  public void messageReceived(int to, Message message) {
    long t = System.currentTimeMillis();
    try {
        String str = message.toString();
        System.out.println(str);
        MsgPacket newPacket = MsgPacket.form(str);
        newPacket.display();
        // if (setted == false) {
        //     MyCanvas.initLimit(newPacket);
        //     setted = true;
        // }
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
        else if (args[i].equals("-cmd")){
            commandClassType = args[++i];
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
