package explorviz.visualization.engine.picking

import explorviz.shared.model.Clazz
import explorviz.shared.model.Component
import explorviz.shared.model.helper.CommunicationAppAccumulator
import explorviz.shared.model.helper.EdgeState
import explorviz.visualization.engine.main.ProjectionHelper
import explorviz.visualization.engine.main.WebGLStart
import explorviz.visualization.engine.math.Ray
import explorviz.visualization.highlighting.NodeHighlighter
import explorviz.visualization.highlighting.TraceHighlighter
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import explorviz.visualization.engine.main.WebGLManipulation
import explorviz.visualization.engine.main.SceneDrawer

class ObjectPicker {
	val static eventAndObjects = new HashMap<EventType, List<EventObserver>>

	def static addObject(EventObserver object, EventType event) {
		var objects = eventAndObjects.get(event)

		objects.add(object)

		eventAndObjects.put(event, objects)
	}

	def static removeObject(EventObserver object, EventType event) {
		var objects = eventAndObjects.get(event)

		objects.remove(objects)
	}

	def static clear() {
		eventAndObjects.clear()
		doInit()
	}

	def static init() {
		doInit()
	}

	def static doInit() {
		eventAndObjects.put(EventType::DOUBLECLICK_EVENT, new ArrayList<EventObserver>)
		eventAndObjects.put(EventType::CLICK_EVENT, new ArrayList<EventObserver>)
		eventAndObjects.put(EventType::MOUSEMOVE_EVENT, new ArrayList<EventObserver>)
		eventAndObjects.put(EventType::RIGHTCLICK_EVENT, new ArrayList<EventObserver>)
	}

	def static void handleDoubleClick(int x, int y) {
		pickObject(x, y, EventType::DOUBLECLICK_EVENT)
	}

	def static void handleClick(int x, int y) {
		pickObject(x, y, EventType::CLICK_EVENT)
	}

	def static void handleMouseMove(int x, int y) {
		pickObject(x, y, EventType::MOUSEMOVE_EVENT)
	}

	def static void handleRightClick(int x, int y) {
		pickObject(x, y, EventType::RIGHTCLICK_EVENT)
	}

	private def static pickObject(int xParam, int yParam, EventType event) {
		if (hasEventHandlers(event) && WebGLStart::explorVizVisible) {
			var viewportWidth = WebGLStart::viewportWidth
			var viewportHeight = WebGLStart::viewportHeight
			var x = xParam
			var y = yParam

			if (WebGLStart::webVRMode) {

				// splitting the screen into two parts:
				viewportWidth = viewportWidth / 2

				SceneDrawer::setRightEyeModelViewMatrix

				// center of eye = crosshair		
				x = viewportWidth / 2
				y = viewportHeight / 2
			}

			var modelView = WebGLManipulation::getModelViewMatrix()

			var origin = ProjectionHelper::unproject(x, y, 0, viewportWidth, viewportHeight, modelView)
			var direction = ProjectionHelper::unproject(x, y, 1, viewportWidth, viewportHeight, modelView).sub(origin)

			val ray = new Ray(origin, direction)

			val intersectsList = getIntersectsList(ray, event)

			val intersectObject = getTopOrCommunicationClazzEntityFromList(ray, intersectsList)

			if (intersectObject != null) {
				val clickEvent = new ClickEvent()
				clickEvent.positionX = origin.x
				clickEvent.positionX = origin.y
				clickEvent.originalClickX = xParam
				clickEvent.originalClickY = yParam
				clickEvent.object = intersectObject

				fireEvent(event, intersectObject, clickEvent)
			}
		}
	}

	private def static hasEventHandlers(EventType event) {
		eventAndObjects.get(event) != null && !eventAndObjects.get(event).empty
	}

	private def static getIntersectsList(Ray ray, EventType event) {
		val intersectsList = new ArrayList<EventObserver>
		val objects = eventAndObjects.get(event)

		for (object : objects) {
			for (primitiveObject : object.primitiveObjects) {
				if (ray.intersects(primitiveObject)) {
					intersectsList.add(object)
				}
			}
		}

		intersectsList
	}

	private def static EventObserver getTopOrCommunicationClazzEntityFromList(Ray ray, List<EventObserver> entities) {
		var topCoefficient = Float::MAX_VALUE
		var EventObserver topEntity = null

		var commuTopCoefficient = Float::MAX_VALUE
		var CommunicationAppAccumulator commu = null

		for (entity : entities) {
			for (primitiveObject : entity.primitiveObjects) {
				var currentCoefficient = ray.getIntersectCoefficient(primitiveObject)

				if (entity instanceof CommunicationAppAccumulator) {
					if (NodeHighlighter::isCurrentlyHighlighting() || TraceHighlighter::isCurrentlyHighlighting) {
						if (entity.state != EdgeState.TRANSPARENT && entity.state != EdgeState.HIDDEN &&
							entity.state != EdgeState.NORMAL) {

							// highlighted edge found...
							commuTopCoefficient = Float.MIN_VALUE
							commu = entity
						}
					}

					if (commuTopCoefficient > currentCoefficient) {
						commuTopCoefficient = currentCoefficient
						commu = entity
					}
				} else {
					if (topCoefficient > currentCoefficient) {
						topCoefficient = currentCoefficient
						topEntity = entity
					}
				}
			}
		}

		if (topEntity instanceof Component) {
			if (!topEntity.opened) {
				return topEntity
			}
		} else if (topEntity instanceof Clazz) {
			return topEntity
		}

		if (commu != null) commu else topEntity
	}

	private def static fireEvent(EventType event, EventObserver intersectObject, ClickEvent clickEvent) {
		if (event == EventType::CLICK_EVENT) {
			intersectObject.mouseClickHandler.handleClick(clickEvent)
		} else if (event == EventType::DOUBLECLICK_EVENT) {
			intersectObject.mouseDoubleClickHandler.handleDoubleClick(clickEvent)
		} else if (event == EventType::RIGHTCLICK_EVENT) {
			intersectObject.mouseRightClickHandler.handleRightClick(clickEvent)
		} else if (event == EventType::MOUSEMOVE_EVENT) {
			intersectObject.mouseHoverHandler.handleHover(clickEvent)
		}
	}
}
