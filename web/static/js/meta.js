let Meta = {
  get: function (name) {
    let tag = document.querySelector(`meta[name="${name}"]`);
    let value = tag && tag.content;
    if( value == "" || !value ) value = null;
    return value;
  }
}

export default Meta;
