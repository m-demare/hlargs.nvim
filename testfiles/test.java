import java.util.*;

public class Class {
    private final static Long arg2 = 25L;

    private static int fn(int arg1, int arg2){
        return arg1 * Class.arg2.intValue() +5;
    }

    public static void main(String []args) {
        List<String> strs = Arrays.asList(args);
        try {
            strs.sort((String str1, String str2) -> str1.compareTo(str2));
            System.out.println(strs);
        } catch (Exception e) {
            System.err.println(e);
        }
    }
}

