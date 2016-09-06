package explorviz.visualization.experiment.tools;

public class ExperimentToolsPageJS {

	public static native void prepareModal(String modal) /*-{

		if ($wnd.jQuery("#modalExp").length == 0) {
			$wnd.jQuery("body").prepend(modal);
		}

	}-*/;

	public static native void updateAndShowModal(String body, boolean needsSaveButton,
			String jsonExperiment) /*-{

		$wnd.jQuery("#exp-modal-body").html(body);

		var closeButton = $wnd.jQuery('<button/>', {
			text : 'Close',
			'class' : 'btn btn-secondary',
			'data-dismiss' : 'modal'
		});

		var saveButton = $wnd.jQuery('<button/>', {
			text : 'Save',
			'class' : 'btn btn-secondary',
			click : function() {
				save($wnd.jQuery('#exp-modal-body :input').serializeArray())
			}
		});

		$wnd.jQuery("#exp-modal-footer").html("");

		if (needsSaveButton)
			$wnd.jQuery("#exp-modal-footer").append(saveButton);

		$wnd.jQuery("#exp-modal-footer").append(closeButton);

		$wnd.jQuery("#modalExp").modal("show");

		// save function
		function save(serializedInputs) {

			var jsonObj = {};
			
			if(jsonExperiment)
				jsonObj = JSON.parse(jsonExperiment);
				
			if(!jsonObj["title"]) {
				serializedInputs.forEach(function(element, index, array) {
					jsonObj[element.name] = element.value;			
				});
			}
				
			if(!jsonObj["filename"])
				jsonObj["filename"] = "exp_" + (new Date().getTime().toString()) + ".json";
				
			if(!jsonObj["questionnaires"]) {
				jsonObj["questionnaires"] = [];
			} 
			else {			
				var $questionnaireID = $wnd.jQuery("#questionnareID").val();
				
				if($questionnaireID) {					
					// find questionnaire with this id and then update
					jsonObj["questionnaires"].forEach(function(el, index, array) {
						console.log(el);
						if (el.questionnareID.search($questionnaireID) == 0) {
							serializedInputs.forEach(function(element, index, array) {
								el[element.name] = element.value;			
							});
						}
					});				
				} 
				else {
					// create new questionnaire
					var questionnaireObj = {};
					serializedInputs.forEach(function(element, index, array) {
						questionnaireObj[element.name] = element.value;			
					});
					questionnaireObj["questionnareID"] = "quest" + (new Date().getTime().toString());
					questionnaireObj["questions"] = [];
					
					jsonObj["questionnaires"].push(questionnaireObj);
				}
			}
			
			@explorviz.visualization.experiment.tools.ExperimentToolsPage::saveToServer(Ljava/lang/String;)(JSON.stringify(jsonObj));
			$wnd.jQuery("#modalExp").modal('toggle');

		}

	}-*/;

}