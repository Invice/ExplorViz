package explorviz.visualization.view

import explorviz.visualization.view.ConfigurationPage
import explorviz.visualization.main.PageControl
import explorviz.visualization.experiment.TutorialPage
import explorviz.visualization.experiment.EditQuestionsPage
import explorviz.visualization.experiment.tools.ExperimentToolsPage
import explorviz.visualization.experiment.tools.ExperimentSlider

class PageCaller {
	PageControl pageControl

	new(PageControl pageControlParam) {
		pageControl = pageControlParam
	}

	def void showExplorViz() {
		new ExplorVizPage().render(pageControl)
	}

	def void showConfiguration() {
		new ConfigurationPage().render(pageControl)
	}

	def void showTutorial() {
		new TutorialPage().render(pageControl)
	}

	def void showEditQuestions() {
		new EditQuestionsPage().render(pageControl)
	}

	def void showManageUsersAndRoles() {
		new ManageUsersAndRolesPage().render(pageControl)
	}

	def void showExpTools() {
		new ExperimentToolsPage().render(pageControl)
	}

	def void showExperimentSlider() {
		new ExperimentSlider().render(pageControl)
	}

}
