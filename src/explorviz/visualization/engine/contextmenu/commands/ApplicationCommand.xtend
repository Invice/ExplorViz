package explorviz.visualization.engine.contextmenu.commands

import com.google.gwt.user.client.Command
import explorviz.shared.model.Application
import explorviz.visualization.engine.contextmenu.PopupService

abstract class ApplicationCommand implements Command {
	protected var Application currentApp

	def setCurrentApp(Application app) {
		currentApp = app
	}
	
	override void execute() {
		PopupService::hidePopupMenus
	}
}
