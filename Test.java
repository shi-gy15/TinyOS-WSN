
import java.util.*;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.util.regex.*;

public class Test {
    private static BufferedWriter fout;
    private static String[] patterns;
    private static Pattern[] regs;

    public static void main(String[] args) throws Exception {
        compileRegex();
        fout = new BufferedWriter(new FileWriter("result.txt"));
        String str1 = "1318415711615: Message <Message>\n  [id=0x1c]\n  [seqNo=0x1b]\n  [temperature=0x194a]\n  [humidity=0x104c]\n  [radiation=0x194cs]\n  [time=0x1c]";
        String str2 = "1318415711615: Message <Message>\n  [id=0x10]\n  [seqNo=0xc]\n  [temperature=0x194a]\n  [humidity=0x104c]\n  [radiation=0x194cs]\n  [time=0xa]";
        writeMessage(str1);
        writeMessage(str2);
    }

    public static String wrapper(String raw, int index) {
      switch(index) {
      case 0: // "id"
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
    
    public static void writeMessage(String str) throws Exception{
        //String str = msg.toString();
        Matcher m;
        for (int i = 0; i < regs.length; i++) {
            m = regs[i].matcher(str);
            if (m.find()) {
                fout.write(wrapper(m.group(1), i));
            }
        }
        fout.newLine();
        fout.flush();
    }

    public static void compileRegex() {
        patterns = new String[]{
            "id",
            "seqNo",
            "temperature",
            "humidity",
            "radiation",
            "time"
        };
        regs = new Pattern[patterns.length];
        for (int i = 0; i < regs.length; i++) {
            regs[i] = Pattern.compile(patterns[i] + "=0x([0-9a-zA-Z]+)");
        }
    }
}
