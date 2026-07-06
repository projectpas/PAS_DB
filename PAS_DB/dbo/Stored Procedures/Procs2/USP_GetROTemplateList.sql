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
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

**************************************************************/  
CREATE    PROCEDURE [dbo].[USP_GetROTemplateList]
	@PageNumber INT = NULL,
	@PageSize INT = NULL,
	@SortColumn VARCHAR(50)=NULL,
	@SortOrder INT = NULL,
	@GlobalFilter VARCHAR(50) = '',
	@RepairOrderTemplateNumber VARCHAR(256) = NULL,
	@Partnumber VARCHAR(256) = NULL,
	@PartDescription  VARCHAR(MAX) = NULL,
	@Manufacturer  VARCHAR(250) = NULL,
	@WorkToPerform  VARCHAR(256) = NULL,
	@CustomerName  VARCHAR(100) = NULL,
	@PublicationId  VARCHAR(100) = NULL,
	@VendorName  VARCHAR(100) = NULL,
	@Instruction  VARCHAR(MAX) = NULL,
	@MasterCompanyId BIGINT, 
	@IsdeleteStatus BIT = 0,
	@CreatedBy  VARCHAR(50) = NULL,
	@CreatedDate DATETIME = NULL,
	@UpdatedBy  VARCHAR(50) = NULL,
	@UpdatedDate  DATETIME = NULL,
	@IsDeleted BIT = NULL,
	@EmployeeId BIGINT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY

			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
			SELECT 
					@CurrntEmpTimeZoneDesc = COALESCE(
						ETZ.[Description],  -- Prefer Employee's TimeZone description if available
						LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
					)
				FROM 
					dbo.Employee E WITH (NOLOCK) 
				LEFT JOIN 
					dbo.TimeZone ETZ WITH (NOLOCK) 
					ON E.TimeZoneId = ETZ.TimeZoneId
				LEFT JOIN 
					dbo.LegalEntity LE WITH (NOLOCK) 
					ON E.LegalEntityId = LE.LegalEntityId
				LEFT JOIN 
					dbo.TimeZone LTZ WITH (NOLOCK) 
					ON LE.TimeZoneId = LTZ.TimeZoneId
				WHERE 
					E.EmployeeId = @EmployeeId;

			DECLARE @RecordFrom int;  
			DECLARE  @VendorRMADetailStatus VARCHAR(100)= NULL;  
			SET @RecordFrom = (@PageNumber-1) * @PageSize;  
			IF @IsDeleted IS NULL  
			BEGIN  
			 SET @IsDeleted=0  
			END  
			IF @SortColumn IS NULL  
			BEGIN  
			 SET @SortColumn = UPPER('CreatedDate')  
			END   
			ELSE  
			BEGIN   
			 SET @SortColumn = UPPER(@SortColumn)  
			END  

			;WITH Result AS(  
				SELECT 
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
						(Cast(DBO.ConvertUTCtoLocal(ROT.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as CreatedDate,
						ROT.UpdatedBy,
						(Cast(DBO.ConvertUTCtoLocal(ROT.UpdatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) as UpdatedDate
					   FROM [dbo].[RepairOrderTemplate] ROT WITH(NOLOCK)				
					LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = ROT.[ItemMasterId]
					 AND ISNULL(IM.IsNonStock,0) = 0
					 LEFT JOIN [dbo].[Customer] CM WITH(NOLOCK) ON CM.[CustomerId] = ROT.[CustomerId]
					LEFT JOIN [dbo].[Vendor] VN WITH(NOLOCK) ON VN.[VendorId] = ROT.[VendorId]
					LEFT JOIN [dbo].[Publication] PUB WITH(NOLOCK) ON PUB.[PublicationRecordId] = ROT.[PublicationRecordId] AND PUB.MasterCompanyId = @MasterCompanyId
					LEFT JOIN [dbo].[CapabilityType] CBT WITH(NOLOCK) ON CBT.[CapabilityTypeId] = ROT.[WorkPerformedId] AND CBT.MasterCompanyId = @MasterCompanyId
					WHERE ROT.MasterCompanyId = @MasterCompanyId AND ROT.IsDeleted = @IsdeleteStatus
				),

				FinalResult AS (  
				SELECT RepairOrderTemplateId,RepairOrderTemplateNumber, partnumber,PartDescription,Manufacturer,WorkToPerform,CustomerName,PublicationId,VendorName,Instruction, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsDeleted FROM Result  
				WHERE  (  
				 (@GlobalFilter <>'' AND ((RepairOrderTemplateNumber LIKE '%' +@GlobalFilter+'%' ) OR   
				   (partnumber LIKE '%' +@GlobalFilter+'%') OR 
				   (PartDescription LIKE '%' +@GlobalFilter+'%') OR 
				   (Manufacturer LIKE '%' +@GlobalFilter+'%') OR 
				   (WorkToPerform LIKE '%' +@GlobalFilter+'%') OR
				   (CustomerName LIKE '%' +@GlobalFilter+'%') OR
				   (PublicationId LIKE '%' +@GlobalFilter+'%') OR
				   (VendorName LIKE '%' +@GlobalFilter+'%') OR
				   (Instruction LIKE '%' +@GlobalFilter+'%') OR
				   (CreatedBy LIKE '%' +@GlobalFilter+'%') OR 
				   (UpdatedBy LIKE '%' +@GlobalFilter+'%') OR 
				   (CreatedDate LIKE '%' +@GlobalFilter+'%') OR  
				   (UpdatedDate LIKE '%' +@GlobalFilter+'%') 
				   ))  
				   OR     
				   (@GlobalFilter='' AND (ISNULL(@RepairOrderTemplateNumber,'') ='' OR RepairOrderTemplateNumber LIKE  '%'+ @RepairOrderTemplateNumber+'%') AND   
				   (ISNULL(@Partnumber,'') ='' OR partnumber LIKE '%'+ @Partnumber+'%') AND
				   (ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%'+ @PartDescription+'%') AND
				   (ISNULL(@Manufacturer,'') ='' OR Manufacturer LIKE '%'+ @Manufacturer+'%') AND
				   (ISNULL(@WorkToPerform,'') ='' OR WorkToPerform LIKE '%'+ @WorkToPerform+'%') AND
				   (ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%'+ @CustomerName+'%') AND
				   (ISNULL(@PublicationId,'') ='' OR PublicationId LIKE '%'+ @PublicationId+'%') AND
				   (ISNULL(@VendorName,'') ='' OR VendorName LIKE '%'+ @VendorName+'%') AND
				   (ISNULL(@Instruction,'') ='' OR Instruction LIKE '%'+ @Instruction+'%') AND
				   (ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%'+ @CreatedBy+'%') AND  
				   (ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%'+ @UpdatedBy+'%') AND  
				   (ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS DATE) = CAST(@CreatedDate AS DATE)) AND  
				   (ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS DATE) = CAST(@UpdatedDate AS DATE)) 
				   )  
				   )), 

				   ResultCount AS (Select COUNT(RepairOrderTemplateId) AS NumberOfItems FROM FinalResult)  
					  SELECT RepairOrderTemplateId,RepairOrderTemplateNumber,partnumber,PartDescription,Manufacturer,WorkToPerform, CustomerName,PublicationId,VendorName,Instruction,CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsDeleted, NumberOfItems FROM FinalResult, ResultCount  
  
					  ORDER BY    
					  CASE WHEN (@SortOrder=1 AND @SortColumn='RepairOrderTemplateId')  THEN RepairOrderTemplateId END ASC,
					  CASE WHEN (@SortOrder=1 AND @SortColumn='RepairOrderTemplateNumber')  THEN RepairOrderTemplateNumber END ASC,  
					  CASE WHEN (@SortOrder=1 AND @SortColumn='partnumber')  THEN partnumber END ASC, 
					  CASE WHEN (@SortOrder=1 AND @SortColumn='PartDescription')  THEN PartDescription END ASC, 
					  CASE WHEN (@SortOrder=1 AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
					  CASE WHEN (@SortOrder=1 AND @SortColumn='WorkToPerform')  THEN WorkToPerform END ASC,
					  CASE WHEN (@SortOrder=1 AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
					  CASE WHEN (@SortOrder=1 AND @SortColumn='PublicationId')  THEN PublicationId END ASC,
					  CASE WHEN (@SortOrder=1 AND @SortColumn='VendorName')  THEN VendorName END ASC,
					  CASE WHEN (@SortOrder=1 AND @SortColumn='Instruction')  THEN Instruction END ASC,
					  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,  
					  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,  
					  CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,  
					  CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,   
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='RepairOrderTemplateId')  THEN RepairOrderTemplateId END DESC, 
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='RepairOrderTemplateNumber')  THEN RepairOrderTemplateNumber END DESC,  
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='partnumber')  THEN partnumber END DESC, 
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC, 
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC, 
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkToPerform')  THEN WorkToPerform END DESC, 
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC, 
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='PublicationId')  THEN PublicationId END DESC,
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='Instruction')  THEN Instruction END DESC,
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,  
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,  
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,  
					  CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC
					 OFFSET @RecordFrom ROWS   
					 FETCH NEXT @PageSize ROWS ONLY  
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