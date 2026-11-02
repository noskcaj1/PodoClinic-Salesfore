public with sharing class CpfValidator {
    public static String digitsOnly(String cpf) {
        return cpf == null ? null : cpf.replaceAll('[^0-9]', '');
    }

    public static Boolean isValid(String cpf) {
        String d = digitsOnly(cpf);
        if (d == null || d.length() != 11 || d.replaceAll(d.substring(0, 1), '').length() == 0) {
            return false;
        }
        return checkDigit(d, 9) == Integer.valueOf(d.substring(9, 10))
            && checkDigit(d, 10) == Integer.valueOf(d.substring(10, 11));
    }

    private static Integer checkDigit(String d, Integer len) {
        Integer sum = 0;
        for (Integer i = 0; i < len; i++) {
            sum += Integer.valueOf(d.substring(i, i + 1)) * (len + 1 - i);
        }
        Integer r = Math.mod(sum * 10, 11);
        return r == 10 ? 0 : r;
    }
}
