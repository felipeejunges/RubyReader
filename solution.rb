require 'openssl'
# Por questão de erros no windows, usei essa linha
# Voltei versão do net-http-persistence e obtive erro de SSL
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
require 'json'
require 'mechanize'

consultaStruct = Struct.new(:label,:value)
consultaStruct2 = Struct.new(:Modelos)


def convertMecToJson mec
  mec.page.save('temp.json')
  json = File.read('temp.json')
  File.delete('temp.json')
  return JSON.parse(json);
end

link = 'http://veiculos.fipe.org.br/'
linkapi = link + 'api/veiculos/'
mec = Mechanize.new

mec.get link
mec.post linkapi + 'ConsultarMarcas', { 'codigoTabelaReferencia' => 233, 'codigoTipoVeiculo' => 2 }

array_marca = convertMecToJson(mec).map{|hash| consultaStruct.new(*hash.values)}

codigoMarca = ''
nomeMarca = ''
array_marca.each do |marca|
  if marca.label == 'HARLEY-DAVIDSON'
    codigoMarca = marca.value
    nomeMarca = marca.label
    break
  end
end

mec.post linkapi + 'ConsultarModelos', { 'codigoTabelaReferencia' => 233, 'codigoTipoVeiculo' => 2, 'codigoMarca' => codigoMarca }

jsonModelos = convertMecToJson(mec)
objModelos = consultaStruct2.new jsonModelos['Modelos']

array_modelos = objModelos.Modelos.map{|hash| consultaStruct.new(*hash.values)}
arrayModelos = []
array_modelos.each do |modelo|
  nomeModelo = modelo.label
  arrayAno = []

  mec.post linkapi + 'ConsultarAnoModelo', { 'codigoTabelaReferencia' => 233, 'codigoTipoVeiculo' => 2,
                                             'codigoMarca' => 77, 'codigoModelo' => modelo.value}
  array_ano = convertMecToJson(mec).map{|hash| consultaStruct.new(*hash.values)}
  array_ano.each do |ano|
    arrayAno.push(ano.label)
  end

  arrayModelos.push nomeModelo.to_sym => arrayAno
end
json = {nomeMarca.to_sym => arrayModelos}
file = File.open('solution.json', 'w')
file << json.to_json
file.close_write