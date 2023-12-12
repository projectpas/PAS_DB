

CREATE VIEW [dbo].[vw_DefaultMessage]
AS
SELECT        dbo.DefaultMessage.DefaultMessageId, dbo.DefaultMessage.Description, dbo.Module.ModuleName, dbo.DefaultMessage.Memo, dbo.DefaultMessage.MasterCompanyId, dbo.DefaultMessage.CreatedBy, dbo.DefaultMessage.UpdatedBy, 
                         dbo.DefaultMessage.CreatedDate, dbo.DefaultMessage.UpdatedDate, dbo.DefaultMessage.IsActive, dbo.DefaultMessage.IsDeleted, dbo.DefaultMessage.ModuleID 
FROM            dbo.DefaultMessage INNER JOIN
                         dbo.Module ON dbo.Module.ModuleId = dbo.DefaultMessage.ModuleID