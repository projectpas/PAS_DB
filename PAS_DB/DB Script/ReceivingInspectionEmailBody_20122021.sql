





INSERT INTO [dbo].[EmailTemplateType]
           ([EmailTemplateType]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted])
     VALUES
           ('ReceivingInspectionEmailBody'
           ,0
           ,'admin'
           ,'admin'
           , GETDATE()
           ,GETDATE()
           ,1
           ,0);
		   

INSERT INTO [dbo].[EmailTemplate]
           ([TemplateName]
           ,[TemplateDescription]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted]
           ,[EmailBody]
           ,[EmailTemplateTypeId]
           ,[SubjectName]
           ,[RevNo]
           ,[RevDate])
     VALUES
           ('ReceivingInspectionEmailBody','',1,'admin','admin',GETDATE(),GETDATE(),1,0,'',63,'ReceivingInspectionEmailBody',1,GETDATE()),
		   ('ReceivingInspectionEmailBody','',2,'admin','admin',GETDATE(),GETDATE(),1,0,'',63,'ReceivingInspectionEmailBody',1,GETDATE()),
		   ('ReceivingInspectionEmailBody','',3,'admin','admin',GETDATE(),GETDATE(),1,0,'',63,'ReceivingInspectionEmailBody',1,GETDATE()),
		   ('ReceivingInspectionEmailBody','',4,'admin','admin',GETDATE(),GETDATE(),1,0,'',63,'ReceivingInspectionEmailBody',1,GETDATE()),
		   ('ReceivingInspectionEmailBody','',5,'admin','admin',GETDATE(),GETDATE(),1,0,'',63,'ReceivingInspectionEmailBody',1,GETDATE());
		      

UPDATE EmailTemplate SET EmailBody = 
'<html><body><div><h4>Dear Valued Supplier</h4>     </div>     <div>       <p style="margin-left:56px;">The attached RECEIVING INSPECTION is hereby submitted. We received this part. If you have any question about this order, please contact me.</p>     </div>     <div>       <p>Regards,</p>     </div>     <tbody></tbody>     </table>   </body> </html>'
WHERE TemplateName = 'ReceivingInspectionEmailBody';





