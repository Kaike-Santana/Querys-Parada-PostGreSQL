SELECT resp.email, resp.name, DOS.name
						,CASE when situ.name = 'Aguardando Enriquecimento' then 'Representados sem Contato'
						   when situ.name = 'Aguardando Validação' then 'Representados sem Contato'
							when situ.name = 'Aguardando Contato' then 'Em Contato'
							when situ.name = 'Em Tratativas' then 'Em fase de negociação'
							when situ.name = 'Positivo' then 'Contatos telefônicos'
									ELSE ' '
											 END AS Situação
FROM mail_mail Email

INNER
JOIN mail_mail_res_partner_rel EMAILP
ON EMAIL.id = EMAILP.mail_mail_id 

INNER 
JOIN res_partner resp
ON EMAILP.res_partner_id = resp.id

INNER 
JOIN mmp_pre_dossie DOS
ON resp.id = DOS.contato_id 
LEFT

JOIN         mmp_pre_dossie_status SITU
ON             DOS.dossie_status_id
=             SITU.id

INNER
JOIN mmp_pre_client_group Gru
ON		DOS.group_id =	 Gru.id

INNER
JOIN		 mmp_pre_campanha CA
ON			 DOS.campanha_id
=			 CA.id

WHERE  CA.name = 'Santander Trabalhista AFABESP - 2021 - 1ª LEVA' -- AND Email.state = 'sent'