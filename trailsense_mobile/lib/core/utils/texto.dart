/// Pasa a minúsculas y quita tildes, para comparar textos sin importar acentos.
String normalizarTexto(String texto) {
  const String origen = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const String destino = 'aaaaaeeeeiiiiooooouuuunc';
  final StringBuffer buffer = StringBuffer();
  for (final int rune in texto.toLowerCase().runes) {
    final String c = String.fromCharCode(rune);
    final int i = origen.indexOf(c);
    buffer.write(i >= 0 ? destino[i] : c);
  }
  return buffer.toString();
}