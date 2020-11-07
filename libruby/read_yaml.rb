# coding: utf-8
##
## YAML環境ファイルの読み込み
##  グローバル変数 $conf、
##  Vagrantrfile へ設定書き込み
##  デフォルト値を上書きする形にする
## 
def read_yaml_config(file)
  $vm_config_array = []
  i = 10
  begin
    $conf = YAML.load_file(file)
    $conf.class
    $domain = $conf['domain']
    $conf['sub_domain'] = $domain.split(".")[0]
    $sub_domain = $conf['sub_domain']
    #################################################
    cnf = "vm_spec = [\n"    
    $conf.each do |key1, val1|
      # VMスペックの読み込み
      if val1.class == Array and key1 == "vm_spec"
        $conf[key1].each do |val2|
          wk = {}
          val2.each do |key3, val3|
            if val3 != nil
              wk[key3] = val3
            end
          end
          # public_ipが存在しない場合はwkで補完しない。
          if !(val2.has_key?('public_ip'))
            wk.delete('public_ip')
          end
          cnf = cnf + wk.to_json + ",\n"
          $vm_config_array.push(wk.to_s)
        end
      end    
    end
    return cnf + "]\n"
    #################################################
    
  rescue
    return ""
  end
end

