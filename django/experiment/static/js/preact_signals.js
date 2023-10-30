/* esm.sh - esbuild bundle(@preact/signals@1.1.3) es2022 production */
import{Component as U,options as g}from"preact";import{useMemo as l,useRef as b,useEffect as k}from"/stable/preact@10.15.1/es2022/hooks.js";import{Signal as h,computed as $,signal as y,effect as d}from"/v125/@preact/signals-core@1.3.0/X-ZS9wcmVhY3Q/es2022/signals-core.mjs";import{Signal as O,batch as P,computed as R,effect as V,signal as q}from"/v125/@preact/signals-core@1.3.0/X-ZS9wcmVhY3Q/es2022/signals-core.mjs";var s,p;function a(i,n){g[i]=n.bind(null,g[i]||function(){})}function v(i){p&&p(),p=i&&i.S()}function S(i){var n=this,t=i.data,r=E(t);r.value=t;var f=l(function(){for(var e=n.__v;e=e.__;)if(e.__c){e.__c.__$f|=4;break}return n.__$u.c=function(){n.base.data=f.peek()},$(function(){var o=r.value.value;return o===0?0:o===!0?"":o||""})},[]);return f.value}S.displayName="_st";Object.defineProperties(h.prototype,{constructor:{configurable:!0,value:void 0},type:{configurable:!0,value:S},props:{configurable:!0,get:function(){return{data:this}}},__b:{configurable:!0,value:1}});a("__b",function(i,n){if(typeof n.type=="string"){var t,r=n.props;for(var f in r)if(f!=="children"){var e=r[f];e instanceof h&&(t||(n.__np=t={}),t[f]=e,r[f]=e.peek())}}i(n)});a("__r",function(i,n){v();var t,r=n.__c;r&&(r.__$f&=-2,(t=r.__$u)===void 0&&(r.__$u=t=function(f){var e;return d(function(){e=this}),e.c=function(){r.__$f|=1,r.setState({})},e}())),s=r,v(t),i(n)});a("__e",function(i,n,t,r){v(),s=void 0,i(n,t,r)});a("diffed",function(i,n){v(),s=void 0;var t;if(typeof n.type=="string"&&(t=n.__e)){var r=n.__np,f=n.props;if(r){var e=t.U;if(e)for(var o in e){var u=e[o];u!==void 0&&!(o in r)&&(u.d(),e[o]=void 0)}else t.U=e={};for(var _ in r){var c=e[_],m=r[_];c===void 0?(c=C(t,_,m,f),e[_]=c):c.o(m,f)}}}i(n)});function C(i,n,t,r){var f=n in i&&i.ownerSVGElement===void 0,e=y(t);return{o:function(o,u){e.value=o,r=u},d:d(function(){var o=e.value.value;r[n]!==o&&(r[n]=o,f?i[n]=o:o?i.setAttribute(n,o):i.removeAttribute(n))})}}a("unmount",function(i,n){if(typeof n.type=="string"){var t=n.__e;if(t){var r=t.U;if(r){t.U=void 0;for(var f in r){var e=r[f];e&&e.d()}}}}else{var o=n.__c;if(o){var u=o.__$u;u&&(o.__$u=void 0,u.d())}}i(n)});a("__h",function(i,n,t,r){r<3&&(n.__$f|=2),i(n,t,r)});U.prototype.shouldComponentUpdate=function(i,n){var t=this.__$u;if(!(t&&t.s!==void 0||4&this.__$f)||3&this.__$f)return!0;for(var r in n)return!0;for(var f in i)if(f!=="__source"&&i[f]!==this.props[f])return!0;for(var e in this.props)if(!(e in i))return!0;return!1};function E(i){return l(function(){return y(i)},[])}function j(i){var n=b(i);return n.current=i,s.__$f|=4,l(function(){return $(function(){return n.current()})},[])}function G(i){var n=b(i);n.current=i,k(function(){return d(function(){return n.current()})},[])}export{O as Signal,P as batch,R as computed,V as effect,q as signal,j as useComputed,E as useSignal,G as useSignalEffect};
//# sourceMappingURL=signals.mjs.map