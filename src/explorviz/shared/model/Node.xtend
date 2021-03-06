package explorviz.shared.model

import explorviz.shared.model.helper.DrawNodeEntity
import java.util.ArrayList
import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors

class Node extends DrawNodeEntity {
	@Accessors String ipAddress

	@Accessors double cpuUtilization
	@Accessors long freeRAM
	@Accessors long usedRAM

	@Accessors List<Application> applications = new ArrayList<Application>

	@Accessors var boolean visible = true

	@Accessors NodeGroup parent

	public def String getDisplayName() {
		if (this.parent.opened) {
			if (this.name != null && !this.name.empty && !this.name.startsWith("<")) {
				this.name
			} else {
				this.ipAddress
			}
		} else {
			this.parent.name
		}
	}

	override void destroy() {
		for (application : applications)
			application.destroy()
			
		super.destroy()
	}
}
