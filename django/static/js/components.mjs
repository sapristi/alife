import { h, render } from "preact";
import { setup_pnet_cy } from "cytoscape_utils";
import { pnet_to_cytoscape_elements } from "cytoscape_pnet";
import { useState, useRef, useEffect } from "preact/hooks";
import htm from "htm";

export const html = htm.bind(h);

export const PnetGraphDisplay = ({ pnetSignal }) => {
  const container = useRef(null);
  const [cyWrapper, setCyWrapper] = useState(null);
  const [currentPnetId, setCurrentPnetId] = useState(null);

  useEffect(() => {
    if (container.current) {
      const newWrapper = setup_pnet_cy({ nodes: [], edges: [] }, () => {});
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
