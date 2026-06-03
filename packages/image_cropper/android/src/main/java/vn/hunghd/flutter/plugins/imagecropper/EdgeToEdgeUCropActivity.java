package vn.hunghd.flutter.plugins.imagecropper;

import android.os.Build;
import android.os.Bundle;
import android.view.View;
import androidx.core.graphics.Insets;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsControllerCompat;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import com.yalantis.ucrop.UCropActivity;

public class EdgeToEdgeUCropActivity extends UCropActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        WindowCompat.setDecorFitsSystemWindows(getWindow(), true);
        super.onCreate(savedInstanceState);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            getWindow().setNavigationBarContrastEnforced(false);
        }
        WindowInsetsControllerCompat controller =
            new WindowInsetsControllerCompat(getWindow(), getWindow().getDecorView());
        controller.setAppearanceLightStatusBars(true);
        controller.setAppearanceLightNavigationBars(true);
        applySystemBarInsets();
    }

    private void applySystemBarInsets() {
        final View content = findViewById(android.R.id.content);
        if (content == null) {
            return;
        }
        final int startPaddingLeft = content.getPaddingLeft();
        final int startPaddingTop = content.getPaddingTop();
        final int startPaddingRight = content.getPaddingRight();
        final int startPaddingBottom = content.getPaddingBottom();
        ViewCompat.setOnApplyWindowInsetsListener(content, (view, windowInsets) -> {
            final Insets systemBars = windowInsets.getInsets(
                WindowInsetsCompat.Type.systemBars()
            );
            view.setPadding(
                startPaddingLeft,
                startPaddingTop + systemBars.top,
                startPaddingRight,
                startPaddingBottom + systemBars.bottom
            );
            return windowInsets;
        });
        ViewCompat.requestApplyInsets(content);
    }
}
