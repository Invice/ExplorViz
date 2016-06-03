package explorviz.visualization.experiment

import explorviz.visualization.engine.navigation.Navigation
import explorviz.visualization.main.PageControl
import explorviz.visualization.view.IPage
import explorviz.visualization.engine.main.WebGLStart
import explorviz.visualization.experiment.tools.ExperimentTools
import java.util.ArrayList

class NewExperiment implements IPage {
	private static int i = 0;
	static PageControl pc;
	static ArrayList<String> questions;

	override render(PageControl pageControl) {
		pc = pageControl
		initializeQuestions()
		pageControl.setView(getNextQuestion());

		ExperimentTools::toolsModeActive = true
		TutorialJS.closeTutorialDialog()
		TutorialJS.hideArrows()

		WebGLStart::initWebGL()
		Navigation::registerWebGLKeys()
		NewExperimentJS::init()
	}

	def static protected getNextQuestion() {
		
		var StringBuilder html = new StringBuilder();
		
		if (i < 1 && questions.size() > i) {
			html.append('''
				<div id="expSlider">
				  <div id="expSliderLabel" class="expRotate">
				    Question Interface
				  </div>
				  <div id="expSliderForm">	
				     �getQuestForm(i)�
				     �getButtonCode()� 	
				  </div>
				</div>
			'''.toString())
		} else {
			html.append(''' 
			�getQuestForm(i)�
			�getButtonCode()� 	
			'''.toString())
		}
		i++;
		//TODO add method for adding button code to every new form content
		return html.toString();
	}

	def static protected setNextQuestion(int next) {
		i = next;
	}
	def static protected getButtonCode(){
		return 	'''
		<button id='expBackBtn'>&lt;&lt; Back</button>
		<button id='expSaveBtn'>Save &gt;&gt; </button>'''.toString()	 
	}

	def static protected initializeQuestions() {
		questions = new ArrayList<String>();
		questions.add('''
			Ich bin der Geist, der stets verneint!<br>
			Und das mit Recht; denn alles, was entsteht,<br>
			Ist wert, dass es zugrunde geht;<br>
			Drum besser waer's, dass nichts entstuende.<br>
			So ist denn alles, was ihr Suende,<br>
			Zerstoerung, kurz, das Boese nennt,<br>
			Mein eigentliches Element.<br>
		'''.toString())

		questions.add('''
			<form id='expQuestionForm'>
			  Question �i�
			  <br>
			  First name:
			  <br>
			  <input type='text' name='firstname'>
			  <br> Last name:
			  <br>
			  <input type='text' name='lastname'>
			  <br>
			  <input type='radio' name='gender' value='male' checked> Male
			  <br>
			  <input type='radio' name='gender' value='female'> Female
			  <br>
			  <input type='radio' name='gender' value='other'> Other
			  <br>
			</form>
		'''.toString())
	}

	def static protected getQuestForm(int i) {
		return questions.get(i)
	}
	
	def static protected createtFreeTextForm(String label){
		var freeText = '''test'''.toString();
	}
}
