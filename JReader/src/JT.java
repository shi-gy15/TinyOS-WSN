

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartUtilities;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.*;
import org.jfree.data.*;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.data.category.CategoryDataset;
import org.jfree.data.general.DatasetUtilities;


public class JT {
    public static void main(String[] args) {
        double[][] data = new double[][]{
                {0.21, 0.66, 0.23, 0.40, 0.26},
                {0.25, 0.21, 0.10, 0.40, 0.16}
        };
        String[] rowKeys = {"apple", "pear"};
        String[] columnKeys = {"beijing", "shanghai", "guangzhou", "chengdu", "shenzhen"};
        //getBarData(data, rowKeys, columnKeys);
        CategoryDataset dataset = DatasetUtilities.createCategoryDataset(rowKeys, columnKeys, data);
        JFreeChart chart = ChartFactory.createBarChart("title",
                "x",
                "y",
                dataset,
                PlotOrientation.VERTICAL,
                false,
                false,
                false
        );
        System.out.println("success");
    }
}
