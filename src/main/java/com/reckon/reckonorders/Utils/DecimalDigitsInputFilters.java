package com.reckon.reckonorders.Utils;

import android.text.InputFilter;
import android.text.Spanned;

public class DecimalDigitsInputFilters implements InputFilter {
    private final int digitBeforeZero;
    private final int digitAfterZero;

    public DecimalDigitsInputFilters(int i, int i1) {
        digitBeforeZero = i;
        digitAfterZero = i1;
    }

    /// Regex with Hyphen, for example == -2222.22 or 1111.33 use this ==> "-?(?:([1-9]{1})([0-9]{0," + (digitBeforeZero - 1) + "})?)?(\\.[0-9]{0," + digitAfterZero + "})?"
    /// Regex without hyphen, for example == 2222.22 ==> "(([1-9]{1})([0-9]{0," + (digitBeforeZero - 1) + "})?)?(\\.[0-9]{0," + digitAfterZero + "})?"

    @Override
    public CharSequence filter(CharSequence source, int start, int end, Spanned dest, int dstart, int dend) {
        StringBuilder builder = new StringBuilder(dest);
        builder.replace(dstart, dend, source.subSequence(start, end).toString());
        if (!builder.toString().matches("-?(?:(0|[1-9]{1})([0-9]{0," + (digitBeforeZero - 1) + "})?)?(\\.([0-9]{0," + digitAfterZero + "})?)?")) {
            if (source.length() == 0)
                return dest.subSequence(dstart, dend);
            return "";
        }

        return null;
    }
}