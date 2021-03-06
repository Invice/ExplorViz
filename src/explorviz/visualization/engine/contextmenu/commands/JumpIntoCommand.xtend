package explorviz.visualization.engine.contextmenu.commands

import com.google.gwt.user.client.Command
import explorviz.shared.model.Application
import explorviz.visualization.engine.contextmenu.PopupService
import explorviz.visualization.engine.main.SceneDrawer
import explorviz.visualization.interaction.Usertracking
import explorviz.visualization.experiment.Experiment

class JumpIntoCommand implements Command {
	  var Application currentApp
	
	  def setCurrentApp(Application app) {
	  	currentApp = app
	  }
	
      override execute() {
      	if(!Experiment::tutorial){
      		PopupService::hidePopupMenus()
       		Usertracking::trackApplicationDoubleClick(currentApp);
        	SceneDrawer::createObjectsFromApplication(currentApp, true)
      	}
      }
}