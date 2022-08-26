
SELECT DISTINCT

	IFNULL(fr.fornecedor_terc, f.fornecedor) as terceirizado,
    IFNULL(fr.fornecedor_quart, 'N/A') AS quarteirizado,
    case when PERFGTS.resposta LIKE 'não' then 1 ELSE 0 end as FGTS,
    case when PERINSS.resposta LIKE 'não' then 1 ELSE 0 end as INSS,
    case when PERABVTEX.resposta LIKE '%não%' then 1 ELSE 0 end as ABVTEX,
    IFNULL(fr.cnpj, f.cnpj) as cnpj,
	f.uf,
	cqmax.resposta as ultima_auditoria
    
   FROM 
	Compliance_Questionario cq
    
	LEFT JOIN 
		Fornecedor f
		ON cq.id_fornecedor = f.id_fornecedor
        
	LEFT JOIN	(					SELECT 
                        fr.id_fornecedor_secundario,
						fterc.fornecedor AS fornecedor_terc, 
						IFNULL(fquart.fornecedor, fquart.nome) AS fornecedor_quart,
						fquart.cnpj
						
					FROM 
						fornecedor_relacao fr
						
						JOIN
							Fornecedor fterc
							ON fr.id_fornecedor_principal = fterc.id_fornecedor
							
						JOIN
							Fornecedor fquart
							ON fr.id_fornecedor_secundario = fquart.id_fornecedor
					WHERE
						fr.relacao LIKE '%QUARTEIR%' and fterc.fornecedor like 'MP %'
                        ) fr
                ON cq.id_fornecedor = fr.id_fornecedor_secundario
   
	LEFT JOIN	(SELECT
						a.id_fornecedor, 
						a.id_questionario,
                        resposta
   					
					FROM
						Compliance_Respostas cr
                        
					JOIN (select max(id_questionario) as id_questionario, a.id_fornecedor, a.id_auditoria
                    from Compliance_Questionario a
                    group by a.id_fornecedor, a.id_auditoria) a
                    ON cr.id_questionario = a.id_questionario
                    and a.id_auditoria = 4
                        
					WHERE
						cr.id_pergunta = 4
						
				) cqmax
				ON cq.id_fornecedor = cqmax.id_fornecedor
                
	
	LEFT JOIN 
		Compliance_Respostas crmax
		ON crmax.id_questionario = cqmax.id_questionario
-- PEGAR RESPOSTAS DE ABVTEX	
	LEFT JOIN 
		(SELECT * FROM Compliance_Respostas crmax
        WHERE id_pergunta= '7' ) PERABVTEX
		ON PERABVTEX.id_questionario = cqmax.id_questionario
-- PEGAR RESPOSTAS DE INSS	
	LEFT JOIN 
		(SELECT * FROM Compliance_Respostas crmax
        WHERE id_pergunta= '16' ) PERINSS
		ON PERINSS.id_questionario = cqmax.id_questionario
-- PEGAR RESPOSTAS DE FGTS	
    LEFT JOIN 
		(SELECT * FROM Compliance_Respostas crmax
        WHERE id_pergunta= '17' ) PERFGTS
		ON PERFGTS.id_questionario = cqmax.id_questionario
-- PEGAR AS PERGUNTAS        
	LEFT JOIN
		Compliance_Perguntas cp
        ON crmax.id_pergunta = cp.id_pergunta
	WHERE 
		cqmax.id_questionario = cq.id_questionario
		AND IFNULL(fr.fornecedor_terc, f.fornecedor) IS NOT NULL
		AND IFNULL(fr.fornecedor_terc, f.fornecedor) NOT LIKE '%RGS%COMEX%'
		AND IFNULL(fr.fornecedor_terc, f.fornecedor) LIKE 'MP %'
		AND IFNULL(fr.fornecedor_terc, f.fornecedor) NOT LIKE '%test%'
		AND IFNULL(fr.fornecedor_terc, f.fornecedor) NOT LIKE '%DUTRA CORRENTES%'
		AND IFNULL(fr.fornecedor_terc, f.fornecedor) NOT LIKE '%NAFLOR TEX%'
		AND IFNULL(fr.fornecedor_terc, f.fornecedor) NOT LIKE '%JULIA%TRICOT%LUCIANO%'
		AND IFNULL(fr.fornecedor_terc, f.fornecedor) NOT LIKE '%RENEE HENRIQUES%'
		AND IFNULL(fr.fornecedor_quart, 'N/A') NOT LIKE '%(%AZZEDIN%)%'
		AND IFNULL(fr.fornecedor_quart, 'N/A') NOT LIKE '%(%ALCINO%)%'
		AND IFNULL(fr.fornecedor_quart, 'N/A') NOT LIKE '%(%ALTINO%)%'
		AND IFNULL(fr.fornecedor_quart, 'N/A') NOT LIKE 'NV BELA VIDA CON%'
		AND f.inativo <> 1
		AND (cp.peso <> 0 or cp.pergunta LIKE 'PRAZO%' or cp.pergunta like 'O local auditado é em residência (Evidencia moradia de pessoas) ou possui comunicação com a residência' or cp.pergunta like 'verificado pela equipe%' or cp.pergunta like 'cnpj' or  cp.pergunta like 'observa%' )
    
