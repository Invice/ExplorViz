package explorviz.visualization.export

import explorviz.visualization.engine.primitives.Box
import explorviz.visualization.model.ApplicationClientSide
import explorviz.visualization.model.ClazzClientSide
import explorviz.visualization.model.ComponentClientSide
import explorviz.visualization.model.helper.Draw3DNodeEntity
import java.util.List
import explorviz.visualization.layout.application.ApplicationLayoutInterface

class OpenSCADApplicationExporter {
	
	/**
	 * Enable lids for open boxes
	 */
	val static boolean enableLids = true

	/**
	 * Used for lids
	 */
	val static wallThickness = 1.0f	//TODO: Test this value

	/**
	 * Scaling for boxes
	 */
	val static heightScaleFactor = 4.0f

	/**
	 * Create the frame of the SCAD file source code
	 * @param application The application to transform to a 3D model
	 */
	def static String exportApplicationAsOpenSCAD(ApplicationClientSide application) {
		"module application()" + "\n" + "{" + "\n" + "\t union() {" + "\n" + "\t\t" +
			createApplicationComponents(application.components) + "}" + "\n" + "}" + "\n" + "\n" + "application();" +
			"\n" + "\n" + labelBasics()
	}

	/**
	 * Add all single components to the result
	 * @param components A list of all components of the application
	 */
	def private static String createApplicationComponents(List<ComponentClientSide> components) {
		var result = ""
		for (component : components) {
			result = result + createApplicationComponent(component) + createApplicationClazzes(component.clazzes)
		}
		result
	}

	/**
	 * Add subcomponents of components to the result
	 * @param component A component with optional subcomponents
	 */
	def private static String createApplicationComponent(ComponentClientSide component) {
		createApplicationComponents(component.children) + createFromPrimitiveObjects(component)	
	}

	/**
	 * ?
	 */
	def private static String createApplicationClazzes(List<ClazzClientSide> clazzes) {
		var result = ""
		for (clazz : clazzes) {
			result = result + createFromPrimitiveObjects(clazz)
		}
		result
	}

	/**
	 * Check every entity and convert it if it is a box
	 * @param entity The entity to check
	 */
	def private static String createFromPrimitiveObjects(Draw3DNodeEntity entity) {
		var result = ""
		for (primitiveObject : entity.primitiveObjects) {
			if (primitiveObject instanceof Box) {
				result = result 
						+ createFromBox(primitiveObject as Box,
						  entity.name,
						if (entity instanceof ComponentClientSide) {
						(entity as ComponentClientSide).opened
						} else false)
			}
		}
		result
	}

//TODO: 
//kompletter deckel mit wand und label "a=[-90,0,90]"
//klassen keine label (momentan durch gr��e ausgeschaltet)
//h�he evaluieren

	/**
	 * Create cube for SCAD files
	 * @param box The box to transform
	 */
	def private static String createFromBox(Box box, String name, boolean opened) {
		val cubeSizeMin = 5.0f
		val cubeSizeMax = 50.0f
		var result = ""
		if (enableLids && opened 
			&& cubeSizeMin <= (box.extensionInEachDirection.z * 2f) 
			&& (box.extensionInEachDirection.z * 2f) <= cubeSizeMax) {

			val wallHeight = 17.0f
			val wallOffest = 60.0f

			result = 
			//creating base 
			"translate([" + box.center.x + "," + -1f * box.center.z + "," + box.center.y * heightScaleFactor + "])" + " " + //position in axis
			"color([" + box.color.x + "," + box.color.y + "," + box.color.z + "]) " +	//apply color
			"cube(size = [" + (box.extensionInEachDirection.x * 2f - wallThickness) + "," //cube dimensions
			+ (box.extensionInEachDirection.z * 2f - wallThickness) + "," + //cube dimensions
			box.extensionInEachDirection.y * 2.04f * heightScaleFactor + "], center = true);\n\t\t" //cube dimensions
			
			+ "difference() {" + "\n\t\t\t" //creating lid

			+ "translate([" + box.center.x + "," + -1f * box.center.z + "," + wallOffest + "])" + " " + //position in axis
			"color([" + box.color.x + "," + box.color.y + "," + box.color.z + "]) " +	//apply color
			"cube(size = [" + (box.extensionInEachDirection.x * 2f)+ "," + //cube length
			(box.extensionInEachDirection.z * 2f) + "," + //cube width
			wallHeight + "], center = true);\n\t\t\t" //cube height

			+ "translate([" + box.center.x + "," + -1f * box.center.z + "," + (wallOffest - wallHeight/2f) + "])" + " " + //position in axis
			"cube(size = [" + (box.extensionInEachDirection.x * 2f - wallThickness)+ "," + //cube length
			(box.extensionInEachDirection.z * 2f - wallThickness) + "," + //cube width
			(wallHeight - wallThickness) + "], center = true);\n\t\t" + //cube height
			"}\n\t\t"

			+ labelCreate(name,box.extensionInEachDirection.z * 2.0f,
							box.center.x - box.extensionInEachDirection.x,
							box.center.z,
							wallOffest)
			
		} else {
			
		result = 
		"translate([" + box.center.x + "," + -1f * box.center.z + "," + box.center.y * heightScaleFactor + "])" + " " + //position in axis
		"color([" + box.color.x + "," + box.color.y + "," + box.color.z + "]) " +	//apply color
		"cube(size = [" + box.extensionInEachDirection.x * 2f + "," + box.extensionInEachDirection.z * 2f + "," + //cube dimensions
		box.extensionInEachDirection.y * 2.04f * heightScaleFactor + "], center = true);\n\t\t" //cube dimensions
			
		}
		
		result = result + labelCreate(name, box, opened)
	}

	/**
	 * Creating a 3D label for a box; opened and closed
	 * @param text The text of the label
	 * @param box The object to label 
	 */
	def private static String labelCreate(String text, Box box, boolean opened) {
		val result = ""
		val charDimensions = 6f
		val min_scale = 0.2f
		var scale = 0.6f

		if (opened) {
			while (((text.length as float) * charDimensions * scale) > (box.extensionInEachDirection.z * 2.0f - wallThickness)) {
				scale = scale - 0.01f
			}
			
			if (scale >= min_scale) {
				val x = box.center.x - box.extensionInEachDirection.x +
					(ApplicationLayoutInterface.labelInsetSpace / 2f)
				val y = (-1f * box.center.z) + ((text.length as float) * (charDimensions * scale) / 2f)
				val z = (box.center.y * heightScaleFactor) +
					(box.extensionInEachDirection.y * 1.02f * heightScaleFactor)
				return labelPosition(x, y, z, "-90") + labelText(text, scale) + "\n\t\t"
			}
		} else {
			while (((text.length as float) * charDimensions * scale) > (box.extensionInEachDirection.x * 2.0f) ||
				charDimensions * scale > (box.extensionInEachDirection.z * 2.0f - wallThickness)) {
				scale = scale - 0.01f
			}

			if (scale >= min_scale) {
				val x = box.center.x - ((text.length as float) * (charDimensions * scale) / 2f)
				val y = (-1f * box.center.z) - (charDimensions * scale) / 2f
				val z = (box.center.y * heightScaleFactor) +
					(box.extensionInEachDirection.y * 1.02f * heightScaleFactor)
				return labelPosition(x, y, z) + labelText(text, scale) + "\n\t\t"
			}
		}		
		//if (scale >= min_scale) fails
		return result
	}

	/**
	 * Creating a 3D label for a lid
	 * @param text The text of the label
	 * @param width The width of the ground to place the label
	 * @param x The x coordinate of the center of the ground
	 * @param y The y coordinate of the center of the ground
	 * @param z The z coordinate of the center of the ground
	 */
	def private static String labelCreate(String text, float width, float x, float y, float z) {
		val result = ""
		val charDimensions = 6f
		val min_scale = 0.2f
		var scale = 0.6f

		while (((text.length as float) * charDimensions * scale) > width) {
				scale = scale - 0.01f
		}
			
		if (scale >= min_scale) {
			return labelPosition(x,
								(-1f * y) + ((text.length as float) * (charDimensions * scale) / 2f),
								z,
								"a=[-90,0,90]")
					+ labelText(text, scale) + "\n\t\t"
		}
		//if (scale >= min_scale) fails
		return result
	}

	///////////////////////////////////////common label stuff///////////////////////////////////////
	
		/**
	 * Translating the label to a certain position
	 * @param x The x-coordinate on the axis
	 * @param y The y-coordinate on the axis
	 * @param z The z-coordinate on the axis
	 */
	def private static String labelPosition(float x, float y, float z) {
		return "translate([" + x + "," + y + "," + z + "]) "
	}
	
	/**
	 * Translating the label to a certain position with a rotation
	 * @param x The x-coordinate on the axis
	 * @param y The y-coordinate on the axis
	 * @param z The z-coordinate on the axis
	 * @param angle The angle of the rotation
	 */
	def private static String labelPosition(float x, float y, float z, String angle) {
		return "translate([" + x + "," + y + "," + z + "]) " + "rotate(" + angle + ") "
	}

	/**
	 * Printing the text of a label with a fixed scale
	 * @param text The text of the label 
	 */
	def private static String labelText(String text, float scale) {
		"color(\"white\") scale([" + scale + "," + scale + ",1.0]) label(\"" + text + "\");"
	}

	/**
	 * Enable creating labels on 3D model
	 */
	def private static String labelBasics() {
		"module label(text) {" + "\n" +
			"\t chars = \" !\\\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_`abcdefghijklmnopqrstuvwxyz{|}\";" +
			"\n" + "\n" + "\t" + "char_table = [ " +
			"[ 0, 0, 0, 0, 0, 0, 0], [ 4, 0, 4, 4, 4, 4, 4], [ 0, 0, 0, 0,10,10,10]," + "\n" + "\t\t\t\t\t\t" +
			"[10,10,31,10,31,10,10], [ 4,30, 5,14,20,15, 4], [ 3,19, 8, 4, 2,25,24]," + "\n" + "\t\t\t\t\t\t" +
			"[13,18,21, 8,20,18,12], [ 0, 0, 0, 0, 8, 4,12], [ 2, 4, 8, 8, 8, 4, 2]," + "\n" + "\t\t\t\t\t\t" +
			"[ 8, 4, 2, 2, 2, 4, 8], [ 0, 4,21,14,21, 4, 0], [ 0, 4, 4,31, 4, 4, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[ 8, 4,12, 0, 0, 0, 0], [ 0, 0, 0,31, 0, 0, 0], [12,12, 0, 0, 0, 0, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[ 0,16, 8, 4, 2, 1, 0], [14,17,25,21,19,17,14], [14, 4, 4, 4, 4,12, 4]," + "\n" + "\t\t\t\t\t\t" +
			"[31, 8, 4, 2, 1,17,14], [14,17, 1, 2, 4, 2,31], [ 2, 2,31,18,10, 6, 2]," + "\n" + "\t\t\t\t\t\t" +
			"[14,17, 1, 1,30,16,31], [14,17,17,30,16, 8, 6], [ 8, 8, 8, 4, 2, 1,31]," + "\n" + "\t\t\t\t\t\t" +
			"[14,17,17,14,17,17,14], [12, 2, 1,15,17,17,14], [ 0,12,12, 0,12,12, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[ 8, 4,12, 0,12,12, 0], [ 2, 4, 8,16, 8, 4, 2], [ 0, 0,31, 0,31, 0, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[16, 8, 4, 2, 4, 8,16], [ 4, 0, 4, 2, 1,17,14], [14,21,21,13, 1,17,14]," + "\n" + "\t\t\t\t\t\t" +
			"[17,17,31,17,17,17,14], [30,17,17,30,17,17,30], [14,17,16,16,16,17,14]," + "\n" + "\t\t\t\t\t\t" +
			"[30,17,17,17,17,17,30], [31,16,16,30,16,16,31], [16,16,16,30,16,16,31]," + "\n" + "\t\t\t\t\t\t" +
			"[15,17,17,23,16,17,14], [17,17,17,31,17,17,17], [14, 4, 4, 4, 4, 4,14]," + "\n" + "\t\t\t\t\t\t" +
			"[12,18, 2, 2, 2, 2, 7], [17,18,20,24,20,18,17], [31,16,16,16,16,16,16]," + "\n" + "\t\t\t\t\t\t" +
			"[17,17,17,21,21,27,17], [17,17,19,21,25,17,17], [14,17,17,17,17,17,14]," + "\n" + "\t\t\t\t\t\t" +
			"[16,16,16,30,17,17,30], [13,18,21,17,17,17,14], [17,18,20,30,17,17,30]," + "\n" + "\t\t\t\t\t\t" +
			"[30, 1, 1,14,16,16,15], [ 4, 4, 4, 4, 4, 4,31], [14,17,17,17,17,17,17]," + "\n" + "\t\t\t\t\t\t" +
			"[ 4,10,17,17,17,17,17], [10,21,21,21,17,17,17], [17,17,10, 4,10,17,17]," + "\n" + "\t\t\t\t\t\t" +
			"[ 4, 4, 4,10,17,17,17], [31,16, 8, 4, 2, 1,31], [14, 8, 8, 8, 8, 8,14]," + "\n" + "\t\t\t\t\t\t" +
			"[ 0, 1, 2, 4, 8,16, 0], [14, 2, 2, 2, 2, 2,14], [ 0, 0, 0, 0,17,10, 4]," + "\n" + "\t\t\t\t\t\t" +
			"[31, 0, 0, 0, 0, 0, 0], [ 0, 0, 0, 0, 2, 4, 8], [15,17,15, 1,14, 0, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[30,17,17,25,22,16,16], [14,17,16,16,14, 0, 0], [15,17,17,19,13, 1, 1]," + "\n" + "\t\t\t\t\t\t" +
			"[14,16,31,17,14, 0, 0], [ 8, 8, 8,28, 8, 9, 6], [14, 1,15,17,15, 0, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[17,17,17,25,22,16,16], [14, 4, 4, 4,12, 0, 4], [12,18, 2, 2, 2, 6, 2]," + "\n" + "\t\t\t\t\t\t" +
			"[18,20,24,20,18,16,16], [14, 4, 4, 4, 4, 4,12], [17,17,21,21,26, 0, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[17,17,17,25,22, 0, 0], [14,17,17,17,14, 0, 0], [16,16,30,17,30, 0, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[ 1, 1,15,19,13, 0, 0], [16,16,16,25,22, 0, 0], [30, 1,14,16,15, 0, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[ 6, 9, 8, 8,28, 8, 8], [13,19,17,17,17, 0, 0], [ 4,10,17,17,17, 0, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[10,21,21,17,17, 0, 0], [17,10, 4,10,17, 0, 0], [14, 1,15,17,17, 0, 0]," + "\n" + "\t\t\t\t\t\t" +
			"[31, 8, 4, 2,31, 0, 0], [ 2, 4, 4, 8, 4, 4, 2], [ 4, 4, 4, 4, 4, 4, 4]," + "\n" + "\t\t\t\t\t\t" +
			"[ 8, 4, 4, 2, 4, 4, 8] ];" + "\n" + "\n" + "\t" + "dec_table = [ " +
			"\"00000\", \"00001\", \"00010\", \"00011\", \"00100\", \"00101\", \"00110\", \"00111\"," + "\n" +
			"\t\t\t\t\t  " + "\"01000\", \"01001\", \"01010\", \"01011\", \"01100\", \"01101\", \"01110\", \"01111\"," +
			"\n" + "\t\t\t\t\t  " +
			"\"10000\", \"10001\", \"10010\", \"10011\", \"10100\", \"10101\", \"10110\", \"10111\"," + "\n" +
			"\t\t\t\t\t  " + "\"11000\", \"11001\", \"11010\", \"11011\", \"11100\", \"11101\", \"11110\", \"11111\" ];" +
			"\n" + "\t" + "for(itext = [0:len(text)-1]) {" + "\n" + "\t\t" +
			"assign(ichar = search(text[itext],chars,1)[0]) {" + "\n" + "\t\t\t" + "for(irow = [0:6]) {" + "\n" +
			"\t\t\t\t" + "assign(val = dec_table[char_table[ichar][irow]]) {" + "\n" + "\t\t\t\t\t" +
			"for(icol = [0:4]) {" + "\n" + "\t\t\t\t\t\t" + "assign(bit = search(val[icol],\"01\",1)[0]) {" + "\n" +
			"\t\t\t\t\t\t\t" + "if(bit) {" + "\n" + "\t\t\t\t\t\t\t\t" + "translate([icol + (6*itext), irow, 0])" + "\n" +
			"\t\t\t\t\t\t\t\t\t" + "cube([1.0001,1.0001,1]);" + "\n" + "\t" + "}}}}}}}" + "\n" + "}"

	//TODO: Hinweise wegen Copyright auf https://github.com/luser/rpi-lcd-case und http://www.geocities.com/dinceraydin/djlcdsim/chartable.js
	}

}
