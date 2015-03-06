package explorviz.shared.model

import explorviz.shared.model.helper.CommunicationAppAccumulator
import explorviz.shared.model.helper.DrawNodeEntity
import explorviz.shared.model.helper.ELanguage
import java.util.ArrayList
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import explorviz.plugin_client.capacitymanagement.execution.SyncObject

class Application extends DrawNodeEntity implements SyncObject {
	static public int nextId = 0
	@Accessors var int id

	@Accessors var boolean database

	@Accessors var ELanguage programmingLanguage

	@Accessors long lastUsage

	@Accessors Node parent

	@Accessors var List<Component> components = new ArrayList<Component>

	@Accessors var List<CommunicationClazz> communications = new ArrayList<CommunicationClazz>

	@Accessors val transient List<CommunicationAppAccumulator> communicationsAccumulated = new ArrayList<CommunicationAppAccumulator>

	@Accessors var List<Communication> incomingCommunications = new ArrayList<Communication>
	@Accessors var List<Communication> outgoingCommunications = new ArrayList<Communication>
	
	/** new attributes since control-center */
	/** The ScalingGroup can only be references via the name because of client and server sides. */
	@Accessors String scalinggroupName 
	
	@Accessors List<String> arguments = new ArrayList<String>() //list of arguments. first application name.
	@Accessors List<String> dependendOn = new ArrayList<String>() //unique hostnames
		
	@Accessors var boolean lockedUntilExecutionActionFinished = false;
	@Accessors var String pid;
	@Accessors var String startScript;
	@Accessors var int waitTimeForStarting;
	
	@Accessors var double rootCauseRating
	@Accessors var boolean isRankingPositive = true
	@Accessors var double temporaryRating = -1;
	
	new(){
		super()
		id = nextId
		nextId++
	}
	
	
		
	override void destroy() {
		for (component : components)
			component.destroy()
		for (commuAccum : communicationsAccumulated)
			commuAccum.destroy()
		super.destroy()
	}

	def void clearAllPrimitiveObjects() {
		for (component : components)
			component.clearAllPrimitiveObjects()

	//		communicationsAccumulated.x[it.clearAllPrimitiveObjects()] done in extra method
	}

	def void unhighlight() {
		for (component : components)
			component.unhighlight()
	}

	def void openAllComponents() {
		for (component : components)
			component.openAllComponents()
	}
	
	/** new methods since control-center */
	
	override isLockedUntilExecutionActionFinished() {
		return lockedUntilExecutionActionFinished;
	}
	
	override setLockedUntilExecutionActionFinished(boolean locked) {
		lockedUntilExecutionActionFinished = locked;
	}

	def copyAttributs(Application oldApp){
		name = oldApp.getName();
		scalinggroupName = oldApp.getScalinggroupName();
		communications = oldApp.getCommunications();
		incomingCommunications = oldApp.getIncomingCommunications();
		outgoingCommunications = oldApp.getOutgoingCommunications();
		components = oldApp.getComponents();
		
	}
}
