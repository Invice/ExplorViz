package explorviz.visualization.landscapeexchange

import com.google.gwt.user.client.rpc.AsyncCallback

import explorviz.shared.model.Landscape
import explorviz.shared.model.NodeGroup
import explorviz.shared.model.Node
import explorviz.shared.model.Application

import explorviz.visualization.engine.main.SceneDrawer

import explorviz.visualization.model.LandscapeClientSide
import explorviz.visualization.model.NodeGroupClientSide
import explorviz.visualization.model.NodeClientSide
import explorviz.visualization.model.ApplicationClientSide

import explorviz.visualization.engine.math.Vector4f
import explorviz.shared.model.Communication
import explorviz.visualization.model.CommunicationClientSide
import explorviz.visualization.model.ComponentClientSide
import explorviz.shared.model.Component
import java.util.ArrayList
import explorviz.shared.model.Clazz
import explorviz.visualization.model.ClazzClientSide
import java.util.List
import explorviz.visualization.model.CommunicationClazzClientSide
import explorviz.shared.model.CommunicationClazz
import java.util.HashMap

class LandscapeConverter<T> implements AsyncCallback<T> {

	var public static LandscapeClientSide oldLandscape

	static val clazzesCache = new HashMap<String, ClazzClientSide>

	static val componentColors = new ArrayList<Vector4f>

	override onFailure(Throwable caught) {
		// TODO
		//      new ErrorPage().renderWithMessage(pageControl, caught.getMessage())
	}

	def static reset() {
		destroyOldLandscape()
	}

	override onSuccess(T result) {
		val newLandscape = result as Landscape
		if (oldLandscape == null || newLandscape.hash != oldLandscape.hash) {
			if (oldLandscape != null) {
				destroyOldLandscape()
			}
			
			componentColors.clear()

			//			componentColors.add(new Vector4f(0.9f, 0.9f, 0.9f, 1f))
			componentColors.add(new Vector4f(0.733f, 0.851f, 0.855f, 1f))
			componentColors.add(new Vector4f(0.7529f, 0.99f, 1f, 1f))
			componentColors.add(new Vector4f(0.06274f, 0.7137f, 0.1333f, 1f))
			componentColors.add(new Vector4f(0f, 0f, 1f, 1f))
			componentColors.add(new Vector4f(0f, 0f, 0.5f, 1f))
			componentColors.add(new Vector4f(0f, 0f, 0.6f, 1f))

			
			clazzesCache.clear()
			var landscapeCS = convertToLandscapeCS(result as Landscape)
			clazzesCache.clear()
			SceneDrawer::viewScene(landscapeCS, false)

			oldLandscape = landscapeCS
		}
	}

	def static destroyOldLandscape() {
		if (oldLandscape != null) {
			oldLandscape.destroy()
			oldLandscape = null
		}
	}

	def LandscapeClientSide convertToLandscapeCS(Landscape landscape) {
		val landscapeCS = new LandscapeClientSide()
		landscapeCS.hash = landscape.hash

		landscape.nodeGroups.forEach [
			landscapeCS.nodeGroups.add(convertToNodeGroupCS(it, landscapeCS))
		]

		landscape.applicationCommunication.forEach [
			landscapeCS.applicationCommunication.add(convertToCommunicationCS(it, landscapeCS))
		]

		landscapeCS
	}

	def CommunicationClientSide convertToCommunicationCS(Communication communication, LandscapeClientSide landscapeCS) {
		val communicationCS = new CommunicationClientSide()
		communicationCS.requestsPerSecond = communication.requestsPerSecond

		communicationCS.source = seekForIdApplication(communication.source.id, landscapeCS)
		communicationCS.target = seekForIdApplication(communication.target.id, landscapeCS)

		communicationCS
	}

	def seekForIdApplication(int id, LandscapeClientSide landscapeCS) {
		for (nodeGroup : landscapeCS.nodeGroups) {
			for (node : nodeGroup.nodes) {
				for (application : node.applications) {
					if (application.id == id) {
						return application
					}
				}
			}
		}

		return null
	}

	def NodeGroupClientSide convertToNodeGroupCS(NodeGroup nodeGroup, LandscapeClientSide parent) {
		val nodeGroupCS = new NodeGroupClientSide()
		nodeGroupCS.parent = parent
//		nodeGroupCS.openedColor = new Vector4f(0.843f, 0.894f, 0.741f, 1f)
		nodeGroupCS.openedColor = new Vector4f(1f, 1f, 1f, 1f)

		nodeGroup.nodes.forEach [
			nodeGroupCS.nodes.add(convertToNodeCS(it, nodeGroupCS))
		]

		// position is important since children have to be created first
		nodeGroupCS.setOpened(false)

		nodeGroupCS
	}

	def convertToNodeCS(Node node, NodeGroupClientSide parent) {
		val nodeCS = new NodeClientSide()
		nodeCS.parent = parent

		nodeCS.ipAddress = node.ipAddress
		nodeCS.name = node.name
		nodeCS.cpuUtilization = node.cpuUtilization
		nodeCS.memoryConsumption = node.memoryConsumption

		node.applications.forEach [
			nodeCS.applications.add(convertToApplicationCS(it, nodeCS))
		]

		nodeCS
	}

	def ApplicationClientSide convertToApplicationCS(Application application, NodeClientSide parent) {
		val applicationCS = new ApplicationClientSide()
		applicationCS.parent = parent

		applicationCS.id = application.id
		applicationCS.database = application.database
		applicationCS.name = application.name
		applicationCS.image = application.image
		applicationCS.lastUsage = application.lastUsage

		application.components.forEach [
			applicationCS.components.add(convertToComponentCS(it, applicationCS, null, 0, true))
		]

		application.communcations.forEach [
			applicationCS.communications.add(convertToCommunicationComponentCS(it, applicationCS.components))
		]

		applicationCS
	}

	def CommunicationClazzClientSide convertToCommunicationComponentCS(CommunicationClazz commu,
		List<ComponentClientSide> components) {
		val commuCS = new CommunicationClazzClientSide()

		commuCS.requestsPerSecond = commu.requestsPerSecond
		commuCS.averageResponseTime = commu.averageResponseTime
		
		commuCS.source = clazzesCache.get(commu.source.fullQualifiedName)
		commuCS.target = clazzesCache.get(commu.target.fullQualifiedName)

		commuCS
	}

	def ComponentClientSide convertToComponentCS(Component component, ApplicationClientSide belongingApplication,
		ComponentClientSide parentComponent, int index, boolean shouldBeOpened) {
		val componentCS = new ComponentClientSide()
		componentCS.belongingApplication = belongingApplication
		componentCS.parentComponent = parentComponent
		var openNextLevel = shouldBeOpened

		componentCS.name = component.name
		componentCS.fullQualifiedName = component.fullQualifiedName

		if (!openNextLevel) {
			componentCS.opened = false
		} else if (component.children.size == 1) {
			componentCS.opened = true
		} else {
			componentCS.opened = true
			openNextLevel = false
		}

		if (index < componentColors.size()) {
			componentCS.color = componentColors.get(index)
		} else {
			componentCS.color = new Vector4f(0f, 0f, 0.6f, 1f)
		}

		for (child : component.children)
			componentCS.children.add(
				convertToComponentCS(child, belongingApplication, componentCS, index + 1, openNextLevel))

		component.clazzes.forEach [
			componentCS.clazzes.add(convertToClazzCS(it, componentCS, index + 1))
		]

		componentCS
	}

	def ClazzClientSide convertToClazzCS(Clazz clazz, ComponentClientSide parent, int index) {
		val clazzCS = new ClazzClientSide()
		clazzCS.parent = parent

		clazzCS.name = clazz.name
		clazzCS.fullQualifiedName = clazz.fullQualifiedName
		clazzCS.instanceCount = clazz.instanceCount
		
		clazzesCache.put(clazzCS.fullQualifiedName, clazzCS)

		if (index < componentColors.size()) {
			clazzCS.color = componentColors.get(index)
		} else {
			clazzCS.color = new Vector4f(0f, 0f, 0.6f, 1f)
		}

		clazzCS
	}
}
