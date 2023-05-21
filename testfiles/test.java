import java.util.*;

public class Class {
    private final static Long arg2 = 25L;

    private static int fn(Arg arg1, int arg2) {
        return arg1.arg1() * Class.arg2.intValue() + arg2;
    }

    private static Optional<Builder> build(int field, Optional<Integer> anotherFieldOptional) {
        return anotherFieldOptional.map(
                anotherField ->
                    Builder.builder()
                        .field(field)
                        .anotherField(anotherField)
                        .build())
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

