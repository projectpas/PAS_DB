/*************************************************************           
 ** File:   [usp_GetEmployeeCertificationList]           
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to Get RO Template List
 ** Purpose:         
 ** Date:   05-05-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    05-05-2025    Amit Ghediya       Created 

**************************************************************/  
CREATE    PROCEDURE [dbo].[USP_GetROTemplateList]
	@MasterCompanyId BIGINT, 
	@IsdeleteStatus BIT = 0  
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
			 ;WITH rptCTE (TotalRecordsCount, RepairOrderTemplateId,RepairOrderTemplateNumber,ItemMasterId,partnumber,PartDescription,Manufacturer, WorkPerformedId,WorkToPerform, 
			 CustomerId,CustomerName, PublicationRecordId,PublicationId, VendorId,VendorName, Instruction,
				  IsActive, IsDeleted, MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate) 
				 AS (

			 SELECT COUNT(1) OVER () AS TotalRecordsCount,
						ROT.[RepairOrderTemplateId],
						ROT.[RepairOrderTemplateNumber],
	  					ROT.ItemMasterId,
						IM.partnumber,
						IM.PartDescription,
						IM.ManufacturerName AS 'Manufacturer',
						ROT.WorkPerformedId,
						CBT.CapabilityTypeDesc AS 'WorkToPerform',
						ROT.CustomerId,  
						CM.[Name] AS 'CustomerName',
						ROT.PublicationRecordId,  
						PUB.PublicationId,
						ROT.VendorId, 
						VN.VendorName,
						ROT.Instruction,
						ROT.[IsActive],
						ROT.[IsDeleted],
						ROT.[MasterCompanyId],
						ROT.CreatedBy,
						ROT.CreatedDate,
						ROT.UpdatedBy,
						ROT.UpdatedDate
					FROM [dbo].[RepairOrderTemplate] ROT WITH(NOLOCK)				
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = ROT.[ItemMasterId]
					LEFT JOIN [dbo].[Customer] CM WITH(NOLOCK) ON CM.[CustomerId] = ROT.[CustomerId]
					LEFT JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VN.[VendorId] = ROT.[VendorId]
					LEFT JOIN [dbo].[Publication] PUB WITH(NOLOCK) ON PUB.[PublicationRecordId] = ROT.[PublicationRecordId] AND PUB.MasterCompanyId = @MasterCompanyId
					LEFT JOIN [dbo].[CapabilityType] CBT WITH(NOLOCK) ON CBT.[CapabilityTypeId] = ROT.[WorkPerformedId] AND CBT.MasterCompanyId = @MasterCompanyId
					WHERE ROT.MasterCompanyId = @MasterCompanyId AND ROT.IsDeleted = @IsdeleteStatus 

					GROUP BY ROT.RepairOrderTemplateNumber,ROT.RepairOrderTemplateId,ROT.RepairOrderTemplateId,ROT.ItemMasterId,IM.partnumber,IM.PartDescription,IM.ManufacturerName,ROT.WorkPerformedId,CBT.CapabilityTypeDesc, ROT.CustomerId, CM.[Name], ROT.PublicationRecordId,PUB.PublicationId, ROT.VendorId,VN.VendorName, ROT.Instruction,
									ROT.IsActive, ROT.IsDeleted, ROT.MasterCompanyId,ROT.CreatedBy,ROT.CreatedDate,ROT.UpdatedBy,ROT.UpdatedDate
							 )
							 ,FinalCTE(TotalRecordsCount, RepairOrderTemplateId,RepairOrderTemplateNumber,ItemMasterId,partnumber,PartDescription,Manufacturer, WorkPerformedId, WorkToPerform,CustomerId,CustomerName, PublicationRecordId,PublicationId, VendorId,VendorName, Instruction,
									IsActive, IsDeleted, MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate) 
				
							 AS (SELECT DISTINCT TotalRecordsCount, RepairOrderTemplateId,RepairOrderTemplateNumber,ItemMasterId,partnumber,PartDescription,Manufacturer, WorkPerformedId,WorkToPerform, CustomerId,CustomerName, PublicationRecordId,PublicationId, VendorId,VendorName, Instruction,
									IsActive, IsDeleted, MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate FROM rptCTE)

							 SELECT COUNT(2) OVER () AS TotalRecordsCount, RepairOrderTemplateId,RepairOrderTemplateNumber,ItemMasterId,partnumber,PartDescription,Manufacturer, WorkPerformedId,WorkToPerform, CustomerId,CustomerName, PublicationRecordId,PublicationId, VendorId,VendorName, Instruction,
									 IsActive, IsDeleted, MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate
							 FROM FinalCTE FC

							ORDER BY RepairOrderTemplateId DESC	
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetROTemplateList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) + 
			  '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) +    
              '@Parameter3 = ''' + CAST(ISNULL(@IsdeleteStatus, '') AS varchar(max)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END