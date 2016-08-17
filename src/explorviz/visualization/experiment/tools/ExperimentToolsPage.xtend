package explorviz.visualization.experiment.tools

import com.google.gwt.user.client.DOM
import com.google.gwt.user.client.Event
import com.google.gwt.user.client.EventListener
import explorviz.visualization.engine.Logging
import explorviz.visualization.experiment.Questionnaire
import explorviz.visualization.experiment.callbacks.StringCallback
import explorviz.visualization.experiment.callbacks.StringListCallback
import explorviz.visualization.experiment.services.JSONServiceAsync
import explorviz.visualization.main.ExplorViz
import explorviz.visualization.main.JSHelpers
import explorviz.visualization.main.PageControl
import explorviz.visualization.main.Util
import explorviz.visualization.view.IPage
import java.util.ArrayList
import java.util.List

import static explorviz.visualization.experiment.tools.ExperimentTools.*
import explorviz.visualization.experiment.callbacks.VoidFuncCallback

class ExperimentToolsPage implements IPage {

	var static JSONServiceAsync jsonService
	var static PageControl pc
	var static List<String> filteredNames

	override render(PageControl pageControl) {

		pc = pageControl
		pc.setView("")

		JSHelpers::hideElementById("legendDiv")

		ExperimentTools::toolsModeActive = true

		jsonService = Util::getJSONService()
		jsonService.getExperimentNames(new StringListCallback<List<String>>([finishInit]))
	}

	def static void finishInit(List<String> names) {

		filteredNames = new ArrayList<String>()
		for (String s : names) {
			if (s.endsWith(".json"))
				filteredNames.add(s.split(".json").get(0));
		}

		pc.setView('''
				<div style="width: 50%;">
				<button id="newExperimentBtn" type="button" style="display: block;" class="btn btn-default btn-sm">
				<span class="glyphicon glyphicon-plus"></span> Create New Experiment 
				</button>
				</div>
			
				<ul style="padding: 10px;">
					<li class="expHeader">
						<div class="container">
							<div>
								Experiment&nbsp;name
							</div>
						</div>
					</li>
			�IF filteredNames.size > 0�						
				�FOR i : 0 .. filteredNames.size-1�	
					<li class="expEntry">
						<div class="container">
							<div class="expElement expTitle">
								�filteredNames.get(i)�
								  </div>
								  <div class="expElement expListButtons"> 
								  	<a id="expRemoveSpan�i�">
								  	 		<span class="glyphicon glyphicon-remove-circle"></span>
								  	 	</a>
								  </div>
								  <div class="expElement expListButtons">
								<a id="expEditSpan�i�">
								    		<span class="glyphicon glyphicon-cog"></span>
								    	</a>
								  </div>
								   <div class="expElement expListButtons">
								   	 <a id="expPlaySpan�i�">
								   	 	<span class="glyphicon glyphicon-play"></span>
								   	 </a>
								  </div>
								</div>
						</li>
				�ENDFOR�
				�ENDIF�
				</ul>
		'''.toString())

		setupButtonHandler()
	}

	def static private setupButtonHandler() {

		val buttonAdd = DOM::getElementById("newExperimentBtn")
		Event::sinkEvents(buttonAdd, Event::ONCLICK)
		Event::setEventListener(buttonAdd, new EventListener {

			override onBrowserEvent(Event event) {
				showNewExpWindow()
			}
		})

		var i = 0
		for (name : filteredNames) {

			val index = i

			val buttonRemove = DOM::getElementById("expRemoveSpan" + i)
			Event::sinkEvents(buttonRemove, Event::ONCLICK)
			Event::setEventListener(buttonRemove, new EventListener {

				override onBrowserEvent(Event event) {
					jsonService.removeExperiment(name, new VoidFuncCallback<Void>([reloadExpToolsPage]))
				}
			})

			val buttonEdit = DOM::getElementById("expEditSpan" + i)
			Event::sinkEvents(buttonEdit, Event::ONCLICK)
			Event::setEventListener(buttonEdit, new EventListener {

				override onBrowserEvent(Event event) {
					jsonService.getExperimentByName(name, new StringCallback<String>([editExperiment]))
				}
			})

			val buttonPlay = DOM::getElementById("expPlaySpan" + i)
			Event::sinkEvents(buttonPlay, Event::ONCLICK)
			Event::setEventListener(buttonPlay, new EventListener {

				override onBrowserEvent(Event event) {
					Logging::log(buttonPlay.toString)
				}
			})

			i++
		}
	}

	def static void editExperiment(String jsonString) {
		ExperimentSlider::jsonExperiment = jsonString
		ExplorViz::getPageCaller().showExperimentSlider()
	}

	def static void reloadExpToolsPage() {
		ExplorViz::getPageCaller().showExpTools()
	}

	def static getQuestionText(int id) {
		return Questionnaire.questions.get(id).text
	}

	def static showNewExpWindow() {
		ExperimentSlider::jsonExperiment = null
		ExplorViz::getPageCaller().showExperimentSlider()
	}

}