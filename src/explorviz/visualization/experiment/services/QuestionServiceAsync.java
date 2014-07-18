package explorviz.visualization.experiment.services;

import com.google.gwt.user.client.rpc.AsyncCallback;

import explorviz.shared.experiment.Answer;
import explorviz.shared.experiment.Question;

public interface QuestionServiceAsync {

	void getQuestions(AsyncCallback<Question[]> callback);

	void writeAnswer(Answer answer, AsyncCallback<Void> callback);

	void getVocabulary(AsyncCallback<String[]> callback);

	void writeString(String string, String id, AsyncCallback<Void> callback);

	void setMaxTimestamp(long timestamp, AsyncCallback<Void> callback);

	void downloadAnswers(AsyncCallback<String> callback);

}
