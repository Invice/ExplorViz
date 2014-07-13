package explorviz.visualization.renderer

import elemental.html.WebGLTexture
import explorviz.shared.model.Application
import explorviz.shared.model.Clazz
import explorviz.shared.model.Communication
import explorviz.shared.model.Component
import explorviz.shared.model.helper.CommunicationAppAccumulator
import explorviz.visualization.engine.main.WebGLStart
import explorviz.visualization.engine.math.Matrix44f
import explorviz.visualization.engine.math.Vector3f
import explorviz.visualization.engine.math.Vector4f
import explorviz.visualization.engine.navigation.Camera
import explorviz.visualization.engine.primitives.BoxContainer
import explorviz.visualization.engine.primitives.LabelContainer
import explorviz.visualization.engine.primitives.PipeContainer
import explorviz.visualization.engine.primitives.PrimitiveObject
import explorviz.visualization.engine.primitives.Quad
import explorviz.visualization.engine.textures.TextureManager
import explorviz.visualization.experiment.Experiment
import explorviz.visualization.layout.application.ApplicationLayoutInterface
import java.util.ArrayList
import java.util.List
import explorviz.visualization.engine.Logging

class ApplicationRenderer {
	static var Vector3f viewCenterPoint
	static val List<PrimitiveObject> arrows = new ArrayList<PrimitiveObject>(2)

	static var WebGLTexture incomePicture
	static var WebGLTexture outgoingPicture

	static val MIN_X = 0
	static val MAX_X = 1
	static val MIN_Y = 2
	static val MAX_Y = 3
	static val MIN_Z = 4
	static val MAX_Z = 5

	static var Long traceToHighlight = null

	def static void highlightTrace(Long traceId) {
		traceToHighlight = traceId
	}

	def static void unhighlightTrace() {
		traceToHighlight = null
	}

	def static init() {
		incomePicture = TextureManager::createTextureFromImagePath("in_colored.png")
		outgoingPicture = TextureManager::createTextureFromImagePath("out.png")
	}

	def static void drawApplication(Application application, List<PrimitiveObject> polygons,
		boolean firstViewAfterChange) {
		PipeContainer::clear()
		BoxContainer::clear()
		arrows.clear()
		
		LabelContainer::clear()
		application.clearAllPrimitiveObjects

		if (viewCenterPoint == null || firstViewAfterChange) {
			calculateCenterAndZZoom(application)
		}

		application.incomingCommunications.forEach [
			drawIncomingCommunication(it, polygons)
		]

		application.outgoingCommunications.forEach [
			drawOutgoingCommunication(it, polygons)
		]

		drawOpenedComponent(application.components.get(0), polygons, 0)

		drawCommunications(application.communicationsAccumulated, polygons)

		PipeContainer::doPipeCreation
		BoxContainer::doBoxCreation
		Logging.log("Pipes and boxes created, no add arrow")
		polygons.addAll(arrows)
		
		LabelContainer::doLabelCreation
	}

	def static calculateCenterAndZZoom(Application application) {
		val foundation = application.components.get(0)

		val rect = new ArrayList<Float>
		rect.add(foundation.positionX)
		rect.add(foundation.positionX + foundation.width)
		rect.add(foundation.positionY)
		rect.add(foundation.positionY + foundation.height)
		rect.add(foundation.positionZ)
		rect.add(foundation.positionZ + foundation.depth)

		val SPACE_IN_PERCENT = 0.02f

		viewCenterPoint = new Vector3f(rect.get(MIN_X) + ((rect.get(MAX_X) - rect.get(MIN_X)) / 2f),
			rect.get(MIN_Y) + ((rect.get(MAX_Y) - rect.get(MIN_Y)) / 2f),
			rect.get(MIN_Z) + ((rect.get(MAX_Z) - rect.get(MIN_Z)) / 2f))

		var modelView = new Matrix44f();
		modelView = Matrix44f.rotationX(33).mult(modelView)
		modelView = Matrix44f.rotationY(45).mult(modelView)

		val southPoint = new Vector4f(rect.get(MIN_X), rect.get(MIN_Y), rect.get(MAX_Z), 1.0f).sub(
			new Vector4f(viewCenterPoint, 0.0f))
		val northPoint = new Vector4f(rect.get(MAX_X), rect.get(MAX_Y), rect.get(MIN_Z), 1.0f).sub(
			new Vector4f(viewCenterPoint, 0.0f))

		val westPoint = new Vector4f(rect.get(MIN_X), rect.get(MIN_Y), rect.get(MIN_Z), 1.0f).sub(
			new Vector4f(viewCenterPoint, 0.0f))
		val eastPoint = new Vector4f(rect.get(MAX_X), rect.get(MAX_Y), rect.get(MAX_Z), 1.0f).sub(
			new Vector4f(viewCenterPoint, 0.0f))

		var requiredWidth = Math.abs(modelView.mult(westPoint).x - modelView.mult(eastPoint).x)
		requiredWidth += requiredWidth * SPACE_IN_PERCENT
		var requiredHeight = Math.abs(modelView.mult(southPoint).y - modelView.mult(northPoint).y)
		requiredHeight += requiredHeight * SPACE_IN_PERCENT

		val perspective_factor = WebGLStart::viewportWidth / WebGLStart::viewportHeight as float

		val newZ_by_width = requiredWidth * -1f / perspective_factor
		val newZ_by_height = requiredHeight * -1f

		Camera::getVector.z = Math.min(Math.min(newZ_by_width, newZ_by_height), -15f)
	}

	def private static void drawIncomingCommunication(Communication commu, List<PrimitiveObject> polygons) {
		drawInAndOutCommunication(commu, commu.source.name, incomePicture, polygons)
	}

	def private static void drawOutgoingCommunication(Communication commu, List<PrimitiveObject> polygons) {

		drawInAndOutCommunication(commu, commu.target.name, outgoingPicture, polygons)
	}

	def private static void drawInAndOutCommunication(Communication commu, String otherApplication,
		WebGLTexture picture, List<PrimitiveObject> polygons) {
		val center = new Vector3f(commu.pointsFor3D.get(0)).sub(viewCenterPoint)

		val quad = new Quad(center, ApplicationLayoutInterface::externalPortsExtension, picture, null, true, true)

		createLabel(center,
			new Vector3f(ApplicationLayoutInterface::externalPortsExtension.x * 8f,
				ApplicationLayoutInterface::externalPortsExtension.y + 4f,
				ApplicationLayoutInterface::externalPortsExtension.z * 8f), otherApplication, false)

		commu.pointsFor3D.forEach [ point, i |
			commu.primitiveObjects.clear
			if (i < commu.pointsFor3D.size - 1) {
				//				PipeContainer::createPipe(commu,viewCenterPoint, commu.lineThickness, point, commu.pointsFor3D.get(i + 1), false) 
				//				commu.primitiveObjects.add(pipe) TODO
			}
		]

		polygons.add(quad)
	}

	def private static drawCommunications(List<CommunicationAppAccumulator> communicationsAccumulated,
		List<PrimitiveObject> polygons) {
		communicationsAccumulated.forEach [
			var hide = false
			if (traceToHighlight != null) {
				var found = false
				for (aggCommu : it.aggregatedCommunications) {
					if (aggCommu.traceIdToRuntimeMap.get(traceToHighlight) != null) {
						found = true
					}
				}

				hide = !found
			}
			val arrow = Experiment::draw3DTutorialCom(it.source.name, it.target.name, points.get(0), points.get(1), viewCenterPoint)
			arrows.addAll(arrow)
			drawCommunication(points, pipeSize, polygons, it, hide)
		]
	}

	def private static drawCommunication(List<Vector3f> points, float pipeSize, List<PrimitiveObject> polygons,
		CommunicationAppAccumulator commu, boolean hide) {
		for (var i = 0; i < points.size - 1; i++) {
			PipeContainer::createPipe(commu, viewCenterPoint, pipeSize, points.get(i), points.get(i + 1), hide)
		}
	}

	def private static void drawOpenedComponent(Component component, List<PrimitiveObject> polygons, int index) {
		BoxContainer::createBox(component, viewCenterPoint, true)

		val labelviewCenterPoint = new Vector3f(
			component.centerPoint.x - component.extension.x + ApplicationLayoutInterface::labelInsetSpace / 2f,
			component.centerPoint.y, component.centerPoint.z).sub(viewCenterPoint)

		val labelExtension = new Vector3f(ApplicationLayoutInterface::labelInsetSpace / 4f, component.extension.y,
			component.extension.z)

		createLabelOpenPackages(labelviewCenterPoint, labelExtension, component.name, if (index == 0) false else true)

		component.clazzes.forEach [
			if (component.opened) {
				drawClazz(it, polygons)
			}
		]

		component.children.forEach [
			if (it.opened) {
				drawOpenedComponent(it, polygons, index + 1)
			} else {
				if (component.opened) {
					drawClosedComponents(it, polygons)
				}
			}
		]

		val arrow = Experiment::draw3DTutorial(component.name,
			new Vector3f(component.positionX, component.positionY, component.positionZ), component.width,
			component.height, component.depth, viewCenterPoint, false)
		arrows.addAll(arrow)
	}

	def private static void drawClosedComponents(Component component, List<PrimitiveObject> polygons) {
		BoxContainer::createBox(component, viewCenterPoint, false)

		createLabel(component.centerPoint.sub(viewCenterPoint), component.extension, component.name, true)




		val arrow = Experiment::draw3DTutorial(component.name,
			new Vector3f(component.positionX, component.positionY, component.positionZ), component.width,
			component.height, component.depth, viewCenterPoint, false)
		arrows.addAll(arrow)
	}

	def private static void drawClazz(Clazz clazz, List<PrimitiveObject> polygons) {
		BoxContainer::createBox(clazz, viewCenterPoint, false)
		createLabel(
			clazz.centerPoint.sub(viewCenterPoint),
			clazz.extension,
			clazz.name,
			true
		)

		val arrow = Experiment::draw3DTutorial(clazz.name, new Vector3f(clazz.positionX, clazz.positionY, clazz.positionZ),
			 clazz.width, clazz.height, clazz.depth, viewCenterPoint, true)
		arrows.addAll(arrow)
	}

	def private static void createLabel(Vector3f center, Vector3f itsExtension, String label, boolean white) {
		val yValue = center.y + itsExtension.y + 0.01f

		val xExtension = Math.max(Math.max(itsExtension.x / 6f, itsExtension.z / 6f), 0.65f)
		val zExtension = xExtension

		LabelContainer::createLabel(
			label,
			new Vector3f(center.x - xExtension, yValue, center.z),
			new Vector3f(center.x, yValue, center.z + zExtension),
			new Vector3f(center.x + xExtension, yValue, center.z),
			new Vector3f(center.x, yValue, center.z - zExtension),
			false,
			white
		)
	}

	def private static void createLabelOpenPackages(Vector3f center, Vector3f itsExtension, String label, boolean white) {
		val yValue = center.y + itsExtension.y + 0.01f

		val xExtension = itsExtension.x
		val zExtension = itsExtension.z

		LabelContainer::createLabel(
			label,
			new Vector3f(center.x - xExtension, yValue, center.z - zExtension),
			new Vector3f(center.x - xExtension, yValue, center.z + zExtension),
			new Vector3f(center.x + xExtension, yValue, center.z + zExtension),
			new Vector3f(center.x + xExtension, yValue, center.z - zExtension),
			true,
			white
		)
	}
	
}
