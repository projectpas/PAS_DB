/*************************************************************             
 ** File:   [USP_GetReceivingReconciliationList]             
 ** Author:   
 ** Description: This stored procedure is used to get Reconsilation list
 ** Purpose:           
 ** Date:   
         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
	1                  unknown
	2    09-05-2024    Moin Bloch   added MasterCompanyId Wise Data
**************************************************************/  
-- =============================================
-- exec USP_GetReceivingReconciliationList 40,1,'ReceivingReconciliationId',-1,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1,NULL,0,NULL,NULL,NULL,NULL
-- =============================================
CREATE PROCEDURE [dbo].[USP_GetReceivingReconciliationList]
-- Add the parameters for the stored procedure here
@PageSize int,  
@PageNumber int,  
@SortColumn varchar(50)= null,  
@SortOrder int= null, 
@GlobalFilter varchar(50)=null,
@StatusID int= null,  
@ReceivingReconciliationNumber	varchar(50),
@InvoiceNum varchar(50),
@OpenDate datetime=null,
@Status varchar(50)=null,
@VendorName varchar(50)=null,
@OriginalTotal varchar(50)= null,
@RRTotal varchar(50)=null,
@InvoiceTotal varchar(50)= null,
@DIfferenceAmount varchar(50)= null,
@TotalAdjustAmount varchar(50)= null,
@MasterCompanyId int= null,
@EmployeeId bigint=1,
@IsDeleted bit= null,
@CreatedBy varchar(50),
@CurrencyName varchar(50),
@PartNumberType varchar(50),
@PORODateType date=null,
@LastMSLevel varchar(50)=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	
				DECLARE @RecordFrom int;
				SET @RecordFrom = (@PageNumber-1)*@PageSize;
				IF @IsDeleted IS NULL
				BEGIN
					SET @IsDeleted=0
				END
				
				IF @SortColumn IS NULL
				BEGIN
					SET @SortColumn = 'ReceivingReconciliationId'
				END 
				Else
				BEGIN 
					SET @SortColumn = UPPER(@SortColumn)
				END
				IF @StatusID=0
				BEGIN 
					SET @StatusID=null
				END 

				IF @Status='0'
				BEGIN
					SET @Status = Null
				END
				DECLARE @MSModuleID INT = 4; -- Purchaseorder Management Structure Module ID
				DECLARE @ROMSModuleID INT = 24; -- repairorder Management Structure Module ID
				;WITH Main AS(
						SELECT DISTINCT RRH.[ReceivingReconciliationId]
							,RRH.[ReceivingReconciliationNumber]
							,RRH.[InvoiceNum]
							,RRH.[StatusId]
							,RRH.[Status]
							,RRH.[VendorId]
							,RRH.[VendorName]
							,RRH.[CurrencyId]
							,RRH.[CurrencyName]
							,RRH.[OpenDate]
							,RRH.[OriginalTotal]
							,RRH.[RRTotal]
							,RRH.[InvoiceTotal]
							,RRH.[DIfferenceAmount]
							,RRH.[TotalAdjustAmount]
							,RRH.[MasterCompanyId]
							,RRH.[CreatedBy]
							,RRH.[UpdatedBy]
							,RRH.[CreatedDate]
							,RRH.[UpdatedDate]
							,RRH.[IsActive]
							,RRH.[IsDeleted]						
							,CASE WHEN (SELECT TOP 1 [Type] FROM [dbo].[ReceivingReconciliationDetails] R WITH(NOLOCK) WHERE R.ReceivingReconciliationId = RRH.ReceivingReconciliationId)  = 1 THEN P.LastMSLevel
							ELSE R.LastMSLevel END as 'LastMSLevel' 
							,CASE WHEN (SELECT TOP 1 [Type] FROM [dbo].[ReceivingReconciliationDetails] R WITH(NOLOCK) WHERE R.ReceivingReconciliationId = RRH.ReceivingReconciliationId)  = 1 THEN P.AllMSlevels
							ELSE R.AllMSlevels END as 'AllMSlevels',
							[Type] = (SELECT TOP 1 [Type] FROM [dbo].[ReceivingReconciliationDetails] R WITH(NOLOCK) WHERE R.ReceivingReconciliationId = RRH.ReceivingReconciliationId)
						FROM [dbo].[ReceivingReconciliationHeader] RRH WITH(NOLOCK)  
						LEFT JOIN [dbo].[ReceivingReconciliationDetails] RRD WITH(NOLOCK) ON RRH.ReceivingReconciliationId = RRD.ReceivingReconciliationId
						OUTER APPLY(
							Select top 1 MSD.LastMSLevel,	
								MSD.AllMSlevels FROM [dbo].[ReceivingReconciliationDetails] rrcd WITH(NOLOCK)
								INNER JOIN [dbo].[PurchaseOrder] puo  WITH (NOLOCK) ON rrcd.PurchaseOrderId = puo.PurchaseOrderId
								INNER JOIN [dbo].[PurchaseOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = puo.PurchaseOrderId
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON puo.ManagementStructureId = RMS.EntityStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								where ReceivingReconciliationId=RRH.ReceivingReconciliationId
						)P
						OUTER APPLY(
							Select top 1 MSD.LastMSLevel,	
								MSD.AllMSlevels from [dbo].[ReceivingReconciliationDetails] rrcd WITH (NOLOCK)
								INNER JOIN [dbo].[RepairOrder] puo WITH (NOLOCK) ON rrcd.PurchaseOrderId = puo.RepairOrderId
								INNER JOIN [dbo].[RepairOrderManagementStructureDetails] MSD WITH (NOLOCK) ON MSD.ModuleID = @ROMSModuleID AND MSD.ReferenceID = puo.RepairOrderId
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON puo.ManagementStructureId = RMS.EntityStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								WHERE ReceivingReconciliationId=RRH.ReceivingReconciliationId
						)R WHERE (@StatusID IS NULL OR RRH.StatusId = @StatusID))
						,PartCTE AS(
						SELECT SQ.ReceivingReconciliationId,(CASE WHEN COUNT(DISTINCT po.PurchaseOrderId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',A.PartNumber from [dbo].[ReceivingReconciliationHeader] SQ WITH (NOLOCK)
						LEFT JOIN [dbo].[ReceivingReconciliationDetails] SP WITH (NOLOCK) On SQ.ReceivingReconciliationId=SP.ReceivingReconciliationId
						INNER JOIN [dbo].[PurchaseOrder] po WITH (NOLOCK) On SP.PurchaseOrderId=po.PurchaseOrderId
						OUTER APPLY(
							SELECT 
							   STUFF((SELECT DISTINCT ',' + S.POReference
									  FROM [dbo].[ReceivingReconciliationDetails] S WITH (NOLOCK)
									  Where S.ReceivingReconciliationId=SQ.ReceivingReconciliationId AND (S.PackagingId is NULL OR S.PackagingId=0)
									  FOR XML PATH('')), 1, 1, '') PartNumber
						) A
						GROUP BY SQ.ReceivingReconciliationId,A.PartNumber
						),PartDateCTE AS(
						Select SQ.ReceivingReconciliationId,(Case When Count(DISTINCT po.PurchaseOrderId) > 1 Then 'Multiple' ELse B.PORODate End)  as 'PORODateType',B.PORODate from [dbo].[ReceivingReconciliationHeader] SQ WITH (NOLOCK)
						LEFT JOIN [dbo].[ReceivingReconciliationDetails] SP WITH (NOLOCK) On SQ.ReceivingReconciliationId=SP.ReceivingReconciliationId
						INNER JOIN [dbo].[PurchaseOrder] po WITH (NOLOCK) On SP.PurchaseOrderId=po.PurchaseOrderId
						OUTER APPLY(
							SELECT 
							   STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR, POP.OpenDate , 110)
									  FROM [dbo].[ReceivingReconciliationDetails] S WITH (NOLOCK)
									  INNER JOIN [dbo].[PurchaseOrder] POP WITH (NOLOCK) On S.PurchaseOrderId=POP.PurchaseOrderId
									  Where S.ReceivingReconciliationId=SQ.ReceivingReconciliationId  AND (S.PackagingId is NULL OR S.PackagingId=0)
									  FOR XML PATH('')), 1, 1, '') PORODate
						) B
						GROUP BY SQ.ReceivingReconciliationId,B.PORODate
						)
						,PartROCTE AS(
						SELECT SQ.ReceivingReconciliationId,(Case When Count(DISTINCT po.RepairOrderId) > 1 Then 'Multiple' ELse C.PartNumber End)  as 'PartNumberType',C.PartNumber from [dbo].[ReceivingReconciliationHeader] SQ WITH (NOLOCK)
						LEFT JOIN [dbo].[ReceivingReconciliationDetails] SP WITH (NOLOCK) On SQ.ReceivingReconciliationId=SP.ReceivingReconciliationId
						INNER JOIN [dbo].[RepairOrder] po WITH (NOLOCK) On SP.PurchaseOrderId=po.RepairOrderId
						OUTER APPLY(
							SELECT 
							   STUFF((SELECT DISTINCT ',' + S.POReference
									  FROM [dbo].[ReceivingReconciliationDetails] S WITH (NOLOCK)
									  WHERE S.ReceivingReconciliationId=SQ.ReceivingReconciliationId  AND (S.PackagingId is NULL OR S.PackagingId=0)
									  FOR XML PATH('')), 1, 1, '') PartNumber
						) C
						GROUP BY SQ.ReceivingReconciliationId,C.PartNumber
						),PartRODateCTE AS(
						SELECT SQ.ReceivingReconciliationId,(Case When Count(DISTINCT po.RepairOrderId) > 1 Then 'Multiple' ELse D.PORODate End)  as 'PORODateType',D.PORODate from [dbo].[ReceivingReconciliationHeader] SQ WITH (NOLOCK)
						LEFT JOIN [dbo].[ReceivingReconciliationDetails] SP WITH (NOLOCK) On SQ.ReceivingReconciliationId=SP.ReceivingReconciliationId
						INNER JOIN [dbo].[RepairOrder] po WITH (NOLOCK) On SP.PurchaseOrderId=po.RepairOrderId
						OUTER APPLY(
							SELECT 
							   STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR, POP.OpenDate , 110)
									  FROM [dbo].[ReceivingReconciliationDetails] S WITH (NOLOCK)
									  INNER JOIN [dbo].[RepairOrder] POP WITH (NOLOCK) On S.PurchaseOrderId=POP.RepairOrderId
									  Where S.ReceivingReconciliationId=SQ.ReceivingReconciliationId  AND (S.PackagingId is NULL OR S.PackagingId=0)
									  FOR XML PATH('')), 1, 1, '') PORODate
						) D
						GROUP BY SQ.ReceivingReconciliationId,D.PORODate
						)
						,Result AS(
						SELECT M.ReceivingReconciliationId,M.ReceivingReconciliationNumber,M.InvoiceNum as 'InvoiceNum',M.StatusId,M.Status as 'Status',M.VendorId,M.VendorName,IsNull(M.CurrencyId,0) as 'CurrencyId',M.CurrencyName,M.OpenDate,
									M.OriginalTotal,M.RRTotal,M.InvoiceTotal,M.DIfferenceAmount,M.TotalAdjustAmount,M.CreatedBy,M.UpdatedBy,M.CreatedDate,M.UpdatedDate,M.IsDeleted,M.IsActive,
									M.LastMSLevel,M.AllMSlevels,CASE WHEN M.[Type] = 1 THEN PT.PartNumber ELSE PTRO.PartNumber END as 'PartNumber',CASE WHEN M.[Type] = 1 THEN PT.PartNumberType ELSE PTRO.PartNumberType END as 'PartNumberType',
									CASE WHEN M.[Type] = 1 THEN PTE.PORODate ELSE PTERO.PORODate END as 'PORODate',CASE WHEN M.[Type] = 1 THEN PTE.PORODateType ELSE PTERO.PORODateType END as 'PORODateType'
									from Main M 
						LEFT JOIN PartCTE PT On M.ReceivingReconciliationId=PT.ReceivingReconciliationId
						LEFT JOIN PartDateCTE PTE On M.ReceivingReconciliationId=PTE.ReceivingReconciliationId
						LEFT JOIN PartROCTE PTRO On M.ReceivingReconciliationId=PTRO.ReceivingReconciliationId
						LEFT JOIN PartRODateCTE PTERO On M.ReceivingReconciliationId=PTERO.ReceivingReconciliationId
						WHERE M.MasterCompanyId = @MasterCompanyId AND (
						(@GlobalFilter <>'' AND (
						(M.ReceivingReconciliationNumber LIKE '%' +@GlobalFilter+'%' ) OR
								(M.InvoiceNum LIKE '%' +@GlobalFilter+'%') OR
								(M.LastMSLevel LIKE '%' +@GlobalFilter+'%') OR
								(M.[Status] LIKE '%' +@GlobalFilter+'%') OR
								(M.OriginalTotal LIKE '%' +@GlobalFilter+'%') OR
								(M.RRTotal LIKE '%' +@GlobalFilter+'%') OR
								(M.InvoiceTotal LIKE '%' +@GlobalFilter+'%') OR
								(M.DIfferenceAmount LIKE '%' +@GlobalFilter+'%') OR
								(M.VendorName LIKE '%' +@GlobalFilter+'%') OR
								(CASE WHEN M.[Type] = 1 THEN PT.PartNumberType ELSE PTRO.PartNumberType END LIKE '%' +@GlobalFilter+'%') OR  
								(M.CurrencyName LIKE '%' +@GlobalFilter+'%')
								))
								OR   
								(@GlobalFilter='' AND 
								(ISNULL(@ReceivingReconciliationNumber,'') ='' OR M.ReceivingReconciliationNumber LIKE '%'+@ReceivingReconciliationNumber+'%') AND 
								(ISNULL(@InvoiceNum,'') ='' OR M.InvoiceNum LIKE '%'+@InvoiceNum+'%') AND
								(ISNULL(@VendorName,'') =''  OR M.VendorName LIKE '%'+@VendorName+'%') AND
								(IsNull(@LastMSLevel,'') ='' OR LastMSLevel like '%'+@LastMSLevel+'%') AND
								(ISNULL(@CurrencyName,'') =''  OR M.CurrencyName LIKE '%'+@CurrencyName+'%') AND
								(ISNULL(@PartNumberType,'') =''  OR CASE WHEN M.[Type] = 1 THEN PT.PartNumberType ELSE PTRO.PartNumberType END LIKE '%'+@PartNumberType+'%') AND
								(@OriginalTotal IS  NULL OR M.OriginalTotal=@OriginalTotal) AND
								(@RRTotal IS  NULL OR M.RRTotal=@RRTotal) AND
								(@InvoiceTotal IS  NULL OR M.InvoiceTotal=@InvoiceTotal) AND
								(@DIfferenceAmount IS  NULL OR M.DIfferenceAmount=@DIfferenceAmount) AND
								(ISNULL(@PORODateType,'') ='' OR CASE WHEN M.[Type] = 1 THEN CONVERT(VARCHAR, PTE.PORODateType , 110) ELSE CONVERT(VARCHAR, PTERO.PORODateType , 110) END = CONVERT(VARCHAR, @PORODateType , 110))							
							))								

						),CTE_Count AS (SELECT COUNT(ReceivingReconciliationId) AS NumberOfItems FROM Result)
						SELECT ReceivingReconciliationId,ReceivingReconciliationNumber,InvoiceNum,StatusId,Status,VendorId,VendorName,CurrencyId,CurrencyName,OpenDate
						,OriginalTotal,RRTotal,InvoiceTotal,DIfferenceAmount,TotalAdjustAmount,CreatedDate,UpdatedDate,NumberOfItems,CreatedBy,UpdatedBy,LastMSLevel,AllMSlevels,PartNumber,PartNumberType,PORODate,PORODateType
						FROM Result,CTE_Count
						ORDER BY  
						CASE WHEN (@SortOrder=1 AND @SortColumn='RECEIVINGRECONCILIATIONNUMBER')  THEN ReceivingReconciliationNumber END ASC,
						CASE WHEN (@SortOrder=1 AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END ASC,
						CASE WHEN (@SortOrder=1 AND @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,
						CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,
						CASE WHEN (@SortOrder=1 AND @SortColumn='CURRENCYNAME')  THEN CurrencyName END ASC,
						CASE WHEN (@SortOrder=1 AND @SortColumn='STATUS')  THEN Status END ASC,
						CASE WHEN (@SortOrder=1 AND @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
						CASE WHEN (@SortOrder=1 AND @SortColumn='PORODate')  THEN PORODate END ASC,						
						CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVINGRECONCILIATIONNUMBER')  THEN ReceivingReconciliationNumber END DESC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END DESC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='INVOICENUM')  THEN InvoiceNum END DESC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='CURRENCYNAME')  THEN CurrencyName END DESC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='STATUS')  THEN Status END DESC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END DESC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='PORODate')  THEN PORODate END DESC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
						CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,    
						CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC
						OFFSET @RecordFrom ROWS 
						FETCH NEXT @PageSize ROWS ONLY
				
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'			
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchSOQViewData' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END