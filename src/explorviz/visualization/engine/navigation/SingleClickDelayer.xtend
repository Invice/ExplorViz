package explorviz.visualization.engine.navigation

import com.google.gwt.user.client.Timer
import explorviz.visualization.engine.picking.ObjectPicker

import static explorviz.visualization.engine.navigation.Navigation.*

class SingleClickDelayer extends Timer {
	@Property int x
	@Property int y
	@Property int width
	@Property int height
	@Property boolean leftClick
	@Property boolean myCanceled = false

	override run() {
		if (!myCanceled) {
			Navigation::clicks = 0

			if (leftClick) {
				ObjectPicker::handleClick(x, y, width, height)
			} else {
				ObjectPicker::handleRightClick(x, y, width, height)
			}
		}
	}
}
