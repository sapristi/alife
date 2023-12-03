import { h, render } from "preact";
import { setup_pnet_cy } from "cytoscape_utils";
import { pnet_to_cytoscape_elements } from "cytoscape_pnet";
import { useState, useRef, useEffect } from "preact/hooks";
import { signal, effect, computed } from "@preact/signals";
import { shortMolRepr } from "utils";

import htm from "htm";

export const html = htm.bind(h);

export const PnetGraphPanel = ({ pnetSignal, eventHandler }) => {
  const container = useRef(null);
  const [cyWrapper, setCyWrapper] = useState(null);
  const [currentPnetId, setCurrentPnetId] = useState(null);

  const defautlEventHandler = (event) => {
    console.log("Selected", event);
  };
  useEffect(() => {
    if (container.current) {
      const newWrapper = setup_pnet_cy(
        { nodes: [], edges: [] },
        eventHandler || defautlEventHandler,
      );
      newWrapper.cy.mount(container.current);
      newWrapper.layout.run();
      window.cyWrapper = newWrapper;
      setCyWrapper(newWrapper);
      return () => newWrapper.cy.unmount();
    }
  }, [container]);

  useEffect(() => {
    console.log("Displaying pnet", pnetSignal.value);
    if (pnetSignal.value) {
      if (pnetSignal.value.uid === currentPnetId) {
        cyWrapper.update_pnet(pnetSignal.value);
      } else {
        const pnet_cytoscape = pnet_to_cytoscape_elements(pnetSignal.value);
        cyWrapper.layout = cyWrapper.replace_elements(pnet_cytoscape);
        cyWrapper.update_pnet(pnetSignal.value);
        cyWrapper.layout.run();
        // for some reason need a callback like this, can't pass directly cyWrapper.cy.fit
        const fitCallback = () => {
          cyWrapper.cy.fit();
        };
        setTimeout(fitCallback, 100);
        setCurrentPnetId(pnetSignal.value.uid);
      }
    }
  }, [pnetSignal.value]);
  return html`<div ref=${container} class="cytoscape-container" />`;
};

const TokenPanel = ({ token }) => {
  const [pos, token_str] = token;
  const before = token_str.slice(0, pos);
  const after = token_str.slice(pos);
  return html`<div class="box" style="overflow-wrap: break-word;">
    <span>${before}</span><span style="color: red">▸</span><span>${after}</span>
  </div>`;
};
export const SelectedNodePanel = ({ selectedNodeSignal }) => {
  console.log("SELECTED", selectedNodeSignal.value);
  const node = selectedNodeSignal.value;
  if (node === null) {
    return null;
  }
  if (node.type === "place") {
    const extensions =
      node.extensions.length > 0
        ? html`<div>
            Extensions:
            <ul>
              ${node.extensions.map((ext) => html`<li>${ext}</li>`)}
            </ul>
          </div>`
        : html`<div>No extension</div>`;
    const token = node.token
      ? html`<div>token: <${TokenPanel} token=${node.token} /></div>`
      : html`<div>No token</div>`;

    return html` <div class="box content">
      <h4 class="title">Selected: Place ${node.index}</h4>
      ${token} ${extensions}
    </div>`;
  } else {
    return null;
  }
};

export const makePnetPanels = (pnetSignal) => {
  const selectedNodeId = signal(null);

  const selectedNode = computed(() => {
    // console.log("updating selected", selectedNodeId.value);
    if (selectedNodeId.value === null || pnetSignal.value === null) {
      return null;
    }
    const node_type = selectedNodeId.value[0];
    const node_id = selectedNodeId.value.slice(1);

    let [type, nodes] =
      node_type === "p"
        ? ["place", pnetSignal.value.places]
        : ["transition", pnetSignal.value.transitions];
    for (let node of nodes) {
      if (node.index.toString() === node_id) {
        return { type, ...node };
      }
    }
    console.warn("Didn't find selected node", selectedNodeId.value);
    return null;
  });

  const updateSelectedNodeId = (event) => {
    console.log("Event handler", event);
    selectedNodeId.value = event.id;
  };

  const PnetGraphPanelWrapper = () =>
    PnetGraphPanel({ pnetSignal, eventHandler: updateSelectedNodeId });
  const SelectedNodePanelWrapper = ({}) =>
    SelectedNodePanel({ selectedNodeSignal: selectedNode });

  return {
    PnetGraphPanel: PnetGraphPanelWrapper,
    SelectedNodePanel: SelectedNodePanelWrapper,
  };
};

export const MolRepr = ({ mol }) => {
  return html`<div
    style="overflow: hidden; text-overflow: ellipsis; max-width: 100%"
  >
    <pre>${shortMolRepr(mol)}</pre>
  </div>`;
};
