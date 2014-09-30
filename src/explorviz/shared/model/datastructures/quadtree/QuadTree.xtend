package explorviz.shared.model.datastructures.quadtree

import com.google.gwt.user.client.rpc.IsSerializable
import explorviz.shared.model.Clazz
import explorviz.shared.model.Component
import explorviz.shared.model.helper.Bounds
import explorviz.shared.model.helper.Draw3DNodeEntity
import explorviz.visualization.engine.Logging
import explorviz.visualization.layout.datastructures.graph.Edge
import explorviz.visualization.layout.datastructures.graph.Graph
import explorviz.visualization.layout.datastructures.graph.Vector3fNode
import java.util.ArrayList

class QuadTree implements IsSerializable {
	@Property int level
	@Property transient float insetSpace = 3.97f
	@Property ArrayList<Draw3DNodeEntity> objects = new ArrayList<Draw3DNodeEntity>()
	@Property var boolean checked = false
	@Property var boolean merged = false
	@Property Bounds bounds
	@Property Vector3fNode NP
	@Property Vector3fNode OP
	@Property Vector3fNode SP
	@Property Vector3fNode WP
	@Property Vector3fNode CP
	@Property Vector3fNode TLC
	@Property Vector3fNode TRC
	@Property Vector3fNode BLC
	@Property Vector3fNode BRC
	@Property transient val Graph<Vector3fNode> graph = new Graph<Vector3fNode>()

	@Property QuadTree[] nodes

	public new() {
	}

	new(int pLevel, Bounds pBounds) {
		level = pLevel
		bounds = pBounds
		nodes = newArrayOfSize(4)
	}

	/*
	 * Splits the node into 4 subnodes
	 */
	def void split() {
		var float pWidth = bounds.width / 2f
		var float pDepth = bounds.depth / 2f
		var float x = bounds.positionX
		var float z = bounds.positionZ

		nodes.set(1,
			new QuadTree(this.level + 1, new Bounds(x + pWidth, bounds.positionY, z, pWidth, bounds.height, pDepth)))
		nodes.set(0, new QuadTree(this.level + 1, new Bounds(x, bounds.positionY, z, pWidth, bounds.height, pDepth)))
		nodes.set(3,
			new QuadTree(this.level + 1, new Bounds(x, bounds.positionY, z + pDepth, pWidth, bounds.height, pDepth)))
		nodes.set(2,
			new QuadTree(this.level + 1,
				new Bounds(x + pWidth, bounds.positionY, z + pDepth, pWidth, bounds.height, pDepth)))
	}

	def void setPins(QuadTree quad) {
		if (quad.nodes.get(0) != null) {
			quad.setPins(quad.nodes.get(0))
			quad.setPins(quad.nodes.get(1))
			quad.setPins(quad.nodes.get(2))
			quad.setPins(quad.nodes.get(3))
		} else {

		if (!quad.merged) {
			quad.WP = new Vector3fNode(quad.bounds.positionX + quad.bounds.width / 2f, quad.bounds.positionY,
				quad.bounds.positionZ)
			quad.NP = new Vector3fNode(quad.bounds.positionX + quad.bounds.width, quad.bounds.positionY,
				quad.bounds.positionZ + quad.bounds.depth / 2f)
			quad.OP = new Vector3fNode(quad.bounds.positionX + quad.bounds.width / 2f, quad.bounds.positionY,
				quad.bounds.positionZ + quad.bounds.depth)
			quad.SP = new Vector3fNode(quad.bounds.positionX, quad.bounds.positionY,
				quad.bounds.positionZ + quad.bounds.depth / 2f)
			quad.CP = new Vector3fNode(quad.bounds.positionX + quad.bounds.width / 2f, quad.bounds.positionY,
				quad.bounds.positionZ + quad.bounds.depth / 2f)
			quad.BLC = new Vector3fNode(quad.bounds.positionX, quad.bounds.positionY, quad.bounds.positionZ)
			quad.TLC = new Vector3fNode(quad.bounds.positionX + quad.bounds.width, quad.bounds.positionY,
				quad.bounds.positionZ)
			quad.BRC = new Vector3fNode(quad.bounds.positionX, quad.bounds.positionY,
				quad.bounds.positionZ + quad.bounds.depth)
			quad.TRC = new Vector3fNode(quad.bounds.positionX + quad.bounds.width, quad.bounds.positionY,
				quad.bounds.positionZ + quad.bounds.depth)

			if (!quad.objects.empty) {
				quad.objects.get(0).NP = quad.NP
				quad.objects.get(0).OP = quad.OP
				quad.objects.get(0).SP = quad.SP
				quad.objects.get(0).WP = quad.WP
			}
			}
		}

	}

	def int lookUpQuadrant(Bounds component, Bounds bthBounds, int level) {
		var depth = level;
		var float verticalMidpoint = (bthBounds.width / 2f)
		var float horizontalMidpoint = (bthBounds.depth / 2f)
		var Bounds halfBounds = new Bounds((bthBounds.width / 2f), (bthBounds.depth / 2f))
		if (((component.width) < verticalMidpoint) &&
			((component.depth) < horizontalMidpoint)) {
			depth = lookUpQuadrant(component, halfBounds, level + 1)
		}

		depth
	}

	def boolean insert(QuadTree quad, Draw3DNodeEntity component) {
		var Bounds rectWithSpace

		rectWithSpace = new Bounds(component.width + insetSpace, component.depth + insetSpace)

		if (quad.objects.size > 0) {
			return false
		}
		var rectDepth = lookUpQuadrant(rectWithSpace, new Bounds(quad.bounds.width, quad.bounds.depth), quad.level)
		if (rectDepth == quad.level && quad.nodes.get(0) != null) return false

		if (rectDepth > quad.level) {
			if (quad.nodes.get(0) == null) {
				quad.split()
			}
			if (insert(quad.nodes.get(0), component) == true)
				return true
			else if (insert(quad.nodes.get(1), component) == true)
				return true
			else if (insert(quad.nodes.get(2), component) == true)
				return true
			else if (insert(quad.nodes.get(3), component) == true)
				return true
			else
				return false
		} else {
			if (quad.nodes.get(0) != null) {
	
				if(component instanceof Component) {
					var Component compi = component as Component
					Logging.log("I AM: " + compi.name)
					Logging.log("PARENT: " +compi.parentComponent.name)
				} else {
					var Clazz compi = component as Clazz
										Logging.log("I AM: " + compi.name)
					
					Logging.log("PARENT: " +compi.parent.name)
				}
			
				return false
			
				}
				
			component.positionX = quad.bounds.positionX + (quad.bounds.width - component.width) / 2f
			component.positionZ = quad.bounds.positionZ + (quad.bounds.depth - component.depth) / 2f
			component.positionY = quad.bounds.positionY
			quad.objects.add(component)

			return true
		}
	}

	def Graph<Vector3fNode> getPipeEdges(QuadTree quad) {
		if (!quad.merged) {
			if (quad.nodes.get(0) != null) {
				graph.merge(getPipeEdges(quad.nodes.get(0)))
				graph.merge(getPipeEdges(quad.nodes.get(1)))
				graph.merge(getPipeEdges(quad.nodes.get(2)))
				graph.merge(getPipeEdges(quad.nodes.get(3)))
//				graph.addEdge(new Edge<Vector3fNode>(quad.NP, quad.CP))
//				graph.addEdge(new Edge<Vector3fNode>(quad.OP, quad.CP))
//				graph.addEdge(new Edge<Vector3fNode>(quad.WP, quad.CP))
//				graph.addEdge(new Edge<Vector3fNode>(quad.SP, quad.CP))
			}
			val listPins = #[quad.TLC, quad.TRC, quad.BLC, quad.BRC, quad.NP, quad.OP, quad.SP, quad.WP, quad.CP]

			graph.addVertices(new ArrayList<Vector3fNode>(listPins))
			graph.addEdge(new Edge<Vector3fNode>(quad.TLC, quad.NP))
			graph.addEdge(new Edge<Vector3fNode>(quad.NP, quad.TRC))
			graph.addEdge(new Edge<Vector3fNode>(quad.TRC, quad.OP))
			graph.addEdge(new Edge<Vector3fNode>(quad.OP, quad.BRC))
			graph.addEdge(new Edge<Vector3fNode>(quad.BRC, quad.SP))
			graph.addEdge(new Edge<Vector3fNode>(quad.SP, quad.BLC))
			graph.addEdge(new Edge<Vector3fNode>(quad.BLC, quad.WP))
			graph.addEdge(new Edge<Vector3fNode>(quad.WP, quad.TLC))

			if (!quad.objects.empty) {

				if (quad.objects.get(0) instanceof Component) {
					var Component comp = quad.objects.get(0) as Component
					graph.addEdge(new Edge<Vector3fNode>(quad.NP, comp.quadTree.NP))
					graph.addEdge(new Edge<Vector3fNode>(quad.OP, comp.quadTree.OP))
					graph.addEdge(new Edge<Vector3fNode>(quad.WP, comp.quadTree.WP))
					graph.addEdge(new Edge<Vector3fNode>(quad.SP, comp.quadTree.SP))
				}
			}

		}
		return graph
	}

	def void merge(QuadTree quad) {
		if (quad.nodes.get(0) != null) {
			merge(quad.nodes.get(0))
			merge(quad.nodes.get(1))
			merge(quad.nodes.get(2))
			merge(quad.nodes.get(3))
		}

		if (emptyQuad(quad)) {
			quad.bounds.width = 0f
			quad.bounds.depth = 0f
			quad.merged = true
		}
	}

	def void adjustQuadTree(QuadTree quad) {
		var float moveParameter = 0f
		if (quad.nodes.get(0) != null) {
			adjustQuadTree(quad.nodes.get(0))
			adjustQuadTree(quad.nodes.get(1))
			adjustQuadTree(quad.nodes.get(2))
			adjustQuadTree(quad.nodes.get(3))

			if (quad.nodes.get(1).merged && quad.nodes.get(2).merged) {
				quad.bounds.width = quad.nodes.get(0).bounds.width
			} else {
				var float leftWidth = 0f
				var float rightWidth = 0f

				if (quad.nodes.get(1).bounds.width >= quad.nodes.get(2).bounds.width) {
					rightWidth = quad.nodes.get(1).bounds.width
				} else {
					rightWidth = quad.nodes.get(2).bounds.width
				}

				if (quad.nodes.get(0).bounds.width >= quad.nodes.get(3).bounds.width) {
					leftWidth = quad.nodes.get(0).bounds.width
				} else {
					leftWidth = quad.nodes.get(3).bounds.width
				}

				if (quad.nodes.get(0).bounds.positionX + leftWidth < quad.nodes.get(1).bounds.positionX) {
					moveParameter = quad.nodes.get(1).bounds.positionX -
						(quad.nodes.get(0).bounds.positionX + leftWidth)
					moveQuad(quad.nodes.get(1), -moveParameter)
					moveQuad(quad.nodes.get(2), -moveParameter)
				}

				quad.bounds.width = leftWidth + rightWidth
			}

			if (quad.nodes.get(2).merged && quad.nodes.get(3).merged) {
				if (quad.nodes.get(0).bounds.depth < quad.bounds.depth &&
					quad.nodes.get(0).bounds.depth >= quad.nodes.get(1).bounds.depth) {
					quad.bounds.depth = quad.nodes.get(0).bounds.depth
				} else if (quad.nodes.get(1).bounds.depth < quad.bounds.depth &&
					quad.nodes.get(0).bounds.depth < quad.nodes.get(1).bounds.depth) {
					quad.bounds.depth = quad.nodes.get(1).bounds.depth
				}
			} else {
				var float topDepth = 0f
				var float bottomDepth = 0f

				if (quad.nodes.get(0).bounds.depth >= quad.nodes.get(1).bounds.depth) {
					topDepth = quad.nodes.get(0).bounds.depth
				} else {
					topDepth = quad.nodes.get(1).bounds.depth
				}

				if (quad.nodes.get(2).bounds.depth >= quad.nodes.get(3).bounds.depth) {
					bottomDepth = quad.nodes.get(2).bounds.depth
				} else {
					bottomDepth = quad.nodes.get(3).bounds.depth
				}
				if (quad.nodes.get(0).bounds.positionZ + topDepth < quad.nodes.get(3).bounds.positionZ) {
					var cutZ = quad.nodes.get(3).bounds.positionZ - (quad.nodes.get(0).bounds.positionZ+ topDepth)
					moveQuadZ(quad.nodes.get(2), -cutZ)
					moveQuadZ(quad.nodes.get(3), -cutZ)
				}
				quad.bounds.depth = topDepth + bottomDepth
				
			}
		}

		if (!quad.objects.empty) {
			if (quad.objects.get(0) instanceof Component) {
				var float marginLeft = quad.objects.get(0).positionX - quad.bounds.positionX
				var float marginTop = quad.objects.get(0).positionZ - quad.bounds.positionZ
				quad.bounds.width = quad.objects.get(0).width + 2f * marginLeft
				quad.bounds.depth = quad.objects.get(0).depth + 2f * marginTop
			}
		}
	}

	def void moveQuad(QuadTree quad, float moveParameter) {
		if (quad.nodes.get(0) != null) {
			moveQuad(quad.nodes.get(0), moveParameter)
			moveQuad(quad.nodes.get(1), moveParameter)
			moveQuad(quad.nodes.get(2), moveParameter)
			moveQuad(quad.nodes.get(3), moveParameter)
		}

		quad.bounds.positionX = quad.bounds.positionX + moveParameter

		if (!quad.objects.empty) {
			quad.objects.get(0).positionX = quad.objects.get(0).positionX + moveParameter
			if (quad.objects.get(0) instanceof Component) {
				var Component comp = quad.objects.get(0) as Component
				if (comp.quadTree != null) {
					comp.quadTree.moveQuad(comp.quadTree, moveParameter)
				}
			}
		}
	}

	def void moveQuadZ(QuadTree quad, float moveParameter) {
		if (quad.nodes.get(0) != null) {
			moveQuadZ(quad.nodes.get(0), moveParameter)
			moveQuadZ(quad.nodes.get(1), moveParameter)
			moveQuadZ(quad.nodes.get(2), moveParameter)
			moveQuadZ(quad.nodes.get(3), moveParameter)
		}

		quad.bounds.positionZ = quad.bounds.positionZ + moveParameter

		if (!quad.objects.empty) {
			quad.objects.get(0).positionZ = quad.objects.get(0).positionZ + moveParameter
			if (quad.objects.get(0) instanceof Component) {
				var Component comp = quad.objects.get(0) as Component
				if (comp.quadTree != null) {
					comp.quadTree.moveQuadZ(comp.quadTree, moveParameter)
				}
			}
		}
	}

	def boolean emptyQuad(QuadTree quad) {
		return quad.nodes.get(0) == null && quad.objects.empty == true
	}

}
