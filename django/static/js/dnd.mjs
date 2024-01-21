// Adapted from
// https://codesandbox.io/p/sandbox/preact-drag-and-drop-forked-xos66

import { signal, effect } from "@preact/signals";
import { useState, useRef, useEffect } from "preact/hooks";
import { html } from "components";
import { cssClass } from "utils";

export const DnD = ({ items, Item, keyProp, Handle, onSort }) => {
  let [state, setState] = useState({
    dragging: false,
    draggable: -1,
    dragged: -1,
    over: -1,
  });
  let onMouseDown = (idx) => {
    setState({
      ...state,
      draggable: idx,
    });
  };

  let onMouseUp = () => {
    setState({
      ...state,
      draggable: -1,
    });
  };

  let dragStart = (idx) => (e) => {
    if (e.target.getAttribute("draggable") === "false") return;

    e.dataTransfer.setData("application/json", JSON.stringify(Item));
    e.dataTransfer.effectAllowed = "move";

    setState({
      ...state,
      dragging: true,
      dragged: idx,
      over: idx,
    });
  };
  let dragEnd = (idx) => (e) => {
    setState({
      dragging: false,
      draggable: -1,
      dragged: -1,
      over: -1,
    });
  };
  let dragOver = (idx) => (e) => {
    setState({
      ...state,
      over: idx,
    });

    if (idx === state.dragged) {
      return;
    }

    e.preventDefault();
    e.stopPropagation();
  };

  let drop = (target) => (e) => {
    const { dragged } = state;
    if (dragged === target) return;
    const newItems = items.slice();
    newItems.splice(target, 0, newItems.splice(dragged, 1)[0]);
    onSort(newItems);
  };

  let newItems =
    state.dragging && state.over !== state.dragged ? items.slice() : items;

  if (state.dragging && state.over !== state.dragged) {
    newItems.splice(state.over, 0, newItems.splice(state.dragged, 1)[0]);
  }

  let renderItem = (idx, data) => {
    let handle = html`<${Handle}
      onMouseDown=${() => onMouseDown(idx)}
      onMouseUp=${onMouseUp}
    />`;
    let key = data[keyProp];
    return html` <${Item}
      key=${key}
      data=${data}
      handle=${handle}
      draggable=${state.draggable === idx}
      over=${state.dragging && idx === state.over}
      onDragStart=${dragStart(idx)}
      onDragEnd=${dragEnd(idx)}
      onDragOver=${dragOver(idx)}
      onDrop=${drop(idx)}
      role="option"
      aria-grabbed=${state.dragging && idx === state.over}
    />`;
  };
  return html` <div aria-dropeffect="move">
    ${newItems.map((data, idx) => {
      return renderItem(idx, data);
    })}
  </div>`;
};

export const Item = ({ data, handle, dragged, over, ...props }) => {
  return html`
    <li
      style="-webkit-user-drag: element"
      class=${cssClass({ item: true, dragged, over })}
      ...${props}
    >
      ${handle}
      <section class="content">
        <p>Item #${data.id}</p>
      </section>
    </li>
  `;
};
