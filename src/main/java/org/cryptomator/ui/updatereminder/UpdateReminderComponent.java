package org.cryptomator.ui.updatereminder;

import dagger.Lazy;
import dagger.Subcomponent;
import org.cryptomator.common.settings.Settings;
import org.cryptomator.ui.common.FxmlFile;
import org.cryptomator.ui.common.FxmlScene;

import javafx.scene.Scene;
import javafx.stage.Stage;
import java.time.Duration;
import java.time.Instant;

@UpdateReminderScoped
@Subcomponent(modules = {UpdateReminderModule.class})
public interface UpdateReminderComponent {

	@UpdateReminderWindow
	Stage window();

	@FxmlScene(FxmlFile.UPDATE_REMINDER)
	Lazy<Scene> updateReminderScene();

	Settings settings();

	default void checkAndShowUpdateReminderWindow() {
		var now = Instant.now();
		if (!settings().checkForUpdates.getValue() && settings().lastSuccessfulUpdateCheck.get().isBefore(now.minus(Duration.ofDays(14)))) {
			Stage stage = window();
			stage.setScene(updateReminderScene().get());
			stage.sizeToScene();
			stage.show();
		}
	}

	@Subcomponent.Factory
	interface Factory {

		UpdateReminderComponent create();
	}
}