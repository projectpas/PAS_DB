Update EmailTemplate 
SET EmailBody = '<html><body><div>Dear Sir/Madam,</div><br/><div>Attached is {QuoteNumber} for your consideration. Please call or email with any questions.</div><br/><div>Kind Regards,</div></body></html>'
Where EmailTemplateTypeId = 18
GO

Update EmailTemplate 
SET EmailBody = '<div>Dear Valued Customer,</div><br/><div>Please find attached invoice for services provided. If you have any questions, please contact me.</div><br/><div>Regards,</div>'
Where EmailTemplateTypeId = 48
GO