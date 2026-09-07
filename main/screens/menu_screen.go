components {
  id: "screen_proxy"
  component: "/monarch/screen_proxy.script"
  properties {
    id: "screen_id"
    value: "menu"
    type: PROPERTY_TYPE_HASH
  }
}
embedded_components {
  id: "collectionproxy"
  type: "collectionproxy"
  data: "collection: \"/screens/menu/menu.collection\"\n"
  ""
}
