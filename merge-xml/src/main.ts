import { readFileSync, writeFileSync } from 'node:fs'
import * as libxmljs from 'libxmljs2'

const xml1 = readFileSync(process.argv[2]).toString()
const xml2 = readFileSync(process.argv[3]).toString()

var xmlDoc1 = libxmljs.parseXml(xml1);
var xmlDoc2 = libxmljs.parseXml(xml2);

xmlDoc2.root()

function walkTree(root: libxmljs.Element, firstTree: libxmljs.Document, secondTree: libxmljs.Document) {
    const nodes = root.childNodes()
        .filter(n => n.type() === 'element' || n.type() === 'text')
        .map(n => n as any as libxmljs.Element)
    
    for (const node of nodes.filter(n => n.type() === 'element')) {
        walkTree(node, xmlDoc1, xmlDoc2)
    }

    if (nodes.length === 1) {
        const node = nodes[0]
        const firstNode = firstTree.get(node.path())
        
        if (firstNode) {
            console.log(firstNode.toString())
            console.log(node.toString())
            console.log('---')

            if (firstNode.parent().type() !== 'element') {
                console.log('Cannot swap nodes')
            } else {
                // replace is not yet in the ts or docs but it is there
                (firstNode as any).replace(node)
            }
        } else {
            console.log(`[First node not found at ${node.path()}]`)
            console.log(node.toString())

            // We have to try to create the node, wish us luck ;-)
            const splitXpath = node.path().trim().split('/')
            const previousPaths = [splitXpath[0]] as string []
            for (const path of splitXpath.slice(1, splitXpath.length)) {
                const previousPath = previousPaths.join('/')
                previousPaths.push(path)
                const newPath = previousPaths.join('/')
                const node = firstTree.get(newPath)
                if (!node) {
                    console.log('not found note at', newPath)
                    const parentNode = firstTree.get(previousPath)
                    if (parentNode.type() !== 'element') {
                        console.log(`Cannot get element node at ${previousPath}`)
                        process.exit(1)
                    }

                    const element = parentNode as any as libxmljs.Element
                    element.addChild(secondTree.get(newPath))
                }
            }

            console.log('---')
        }
    }
}

walkTree(xmlDoc2.root(), xmlDoc1, xmlDoc2)

writeFileSync(process.argv[4], xmlDoc1.toString())

// console.log(xmlDoc2.root().childNodes().map(n => n.toString()))

// console.log('hello!')

