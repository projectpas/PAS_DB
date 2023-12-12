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
--@PostDate datetime=null,
--@AccountingPeriod varchar(50)= null,
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
@PORODateType datetime=null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @RecordFrom int;
				SET @RecordFrom = (@PageNumber-1)*@PageSize;
				IF @IsDeleted is null
				Begin
					Set @IsDeleted=0
				End
				print @IsDeleted	
				IF @SortColumn is null
				Begin
					Set @SortColumn = 'ReceivingReconciliationId'
				End 
				Else
				Begin 
					Set @SortColumn=Upper(@SortColumn)
				End


				If @StatusID=0
				Begin 
					Set @StatusID=null
				End 

				If @Status='0'
				Begin
					Set @Status=null
				End
				DECLARE @MSModuleID INT = 4; -- Purchaseorder Management Structure Module ID
				DECLARE @ROMSModuleID INT = 24; -- repairorder Management Structure Module ID
				;With Main AS(
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
							--,P.LastMSLevel
							--,P.AllMSlevels
							,CASE WHEN (SELECT TOP 1 [Type] FROM ReceivingReconciliationDetails R WHERE R.ReceivingReconciliationId = RRH.ReceivingReconciliationId)  = 1 THEN P.LastMSLevel
							ELSE R.LastMSLevel END as 'LastMSLevel' 
							,CASE WHEN (SELECT TOP 1 [Type] FROM ReceivingReconciliationDetails R WHERE R.ReceivingReconciliationId = RRH.ReceivingReconciliationId)  = 1 THEN P.AllMSlevels
							ELSE R.AllMSlevels END as 'AllMSlevels',
							[Type] = (SELECT TOP 1 [Type] FROM ReceivingReconciliationDetails R WHERE R.ReceivingReconciliationId = RRH.ReceivingReconciliationId)
						FROM [dbo].[ReceivingReconciliationHeader] RRH WITH(NOLOCK)  
						LEFT JOIN ReceivingReconciliationDetails RRD ON RRH.ReceivingReconciliationId = RRD.ReceivingReconciliationId
						Outer Apply(
							Select top 1 MSD.LastMSLevel,	
								MSD.AllMSlevels from ReceivingReconciliationDetails rrcd
								Inner JOIN PurchaseOrder puo on rrcd.PurchaseOrderId = puo.PurchaseOrderId
								INNER JOIN dbo.PurchaseOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = puo.PurchaseOrderId
								INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON puo.ManagementStructureId = RMS.EntityStructureId
								INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								where ReceivingReconciliationId=RRH.ReceivingReconciliationId
						)P
						Outer Apply(
							Select top 1 MSD.LastMSLevel,	
								MSD.AllMSlevels from ReceivingReconciliationDetails rrcd
								Inner JOIN RepairOrder puo on rrcd.PurchaseOrderId = puo.RepairOrderId
								INNER JOIN dbo.RepairOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ROMSModuleID AND MSD.ReferenceID = puo.RepairOrderId
								INNER JOIN dbo.RoleManagementStructure RMS WITH (NOLOCK) ON puo.ManagementStructureId = RMS.EntityStructureId
								INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								where ReceivingReconciliationId=RRH.ReceivingReconciliationId
						)R where (@StatusID is null or RRH.StatusId = @StatusID))
						,PartCTE AS(
						Select SQ.ReceivingReconciliationId,(Case When Count(DISTINCT po.PurchaseOrderId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',A.PartNumber from ReceivingReconciliationHeader SQ WITH (NOLOCK)
						Left Join ReceivingReconciliationDetails SP WITH (NOLOCK) On SQ.ReceivingReconciliationId=SP.ReceivingReconciliationId
						inner Join PurchaseOrder po WITH (NOLOCK) On SP.PurchaseOrderId=po.PurchaseOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT DISTINCT ',' + S.POReference
									  FROM ReceivingReconciliationDetails S WITH (NOLOCK)
									  --INNER Join  I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.ReceivingReconciliationId=SQ.ReceivingReconciliationId AND (S.PackagingId is NULL OR S.PackagingId=0)
									  FOR XML PATH('')), 1, 1, '') PartNumber
						) A
						--Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or sq.StatusId=@StatusID))
						Group By SQ.ReceivingReconciliationId,A.PartNumber
						),PartDateCTE AS(
						Select SQ.ReceivingReconciliationId,(Case When Count(DISTINCT po.PurchaseOrderId) > 1 Then 'Multiple' ELse B.PORODate End)  as 'PORODateType',B.PORODate from ReceivingReconciliationHeader SQ WITH (NOLOCK)
						Left Join ReceivingReconciliationDetails SP WITH (NOLOCK) On SQ.ReceivingReconciliationId=SP.ReceivingReconciliationId
						inner Join PurchaseOrder po WITH (NOLOCK) On SP.PurchaseOrderId=po.PurchaseOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR, POP.OpenDate , 110)
									  FROM ReceivingReconciliationDetails S WITH (NOLOCK)
									  INNER Join PurchaseOrder POP WITH (NOLOCK) On S.PurchaseOrderId=POP.PurchaseOrderId
									  --INNER Join  I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.ReceivingReconciliationId=SQ.ReceivingReconciliationId  AND (S.PackagingId is NULL OR S.PackagingId=0)
									  FOR XML PATH('')), 1, 1, '') PORODate
						) B
						--Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or sq.StatusId=@StatusID))
						Group By SQ.ReceivingReconciliationId,B.PORODate
						)
						,PartROCTE AS(
						Select SQ.ReceivingReconciliationId,(Case When Count(DISTINCT po.RepairOrderId) > 1 Then 'Multiple' ELse C.PartNumber End)  as 'PartNumberType',C.PartNumber from ReceivingReconciliationHeader SQ WITH (NOLOCK)
						Left Join ReceivingReconciliationDetails SP WITH (NOLOCK) On SQ.ReceivingReconciliationId=SP.ReceivingReconciliationId
						inner Join RepairOrder po WITH (NOLOCK) On SP.PurchaseOrderId=po.RepairOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT DISTINCT ',' + S.POReference
									  FROM ReceivingReconciliationDetails S WITH (NOLOCK)
									  --INNER Join  I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.ReceivingReconciliationId=SQ.ReceivingReconciliationId  AND (S.PackagingId is NULL OR S.PackagingId=0)
									  FOR XML PATH('')), 1, 1, '') PartNumber
						) C
						--Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or sq.StatusId=@StatusID))
						Group By SQ.ReceivingReconciliationId,C.PartNumber
						),PartRODateCTE AS(
						Select SQ.ReceivingReconciliationId,(Case When Count(DISTINCT po.RepairOrderId) > 1 Then 'Multiple' ELse D.PORODate End)  as 'PORODateType',D.PORODate from ReceivingReconciliationHeader SQ WITH (NOLOCK)
						Left Join ReceivingReconciliationDetails SP WITH (NOLOCK) On SQ.ReceivingReconciliationId=SP.ReceivingReconciliationId
						inner Join RepairOrder po WITH (NOLOCK) On SP.PurchaseOrderId=po.RepairOrderId
						Outer Apply(
							SELECT 
							   STUFF((SELECT DISTINCT ',' + CONVERT(VARCHAR, POP.OpenDate , 110)
									  FROM ReceivingReconciliationDetails S WITH (NOLOCK)
									  INNER Join RepairOrder POP WITH (NOLOCK) On S.PurchaseOrderId=POP.RepairOrderId
									  --INNER Join  I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.ReceivingReconciliationId=SQ.ReceivingReconciliationId  AND (S.PackagingId is NULL OR S.PackagingId=0)
									  FOR XML PATH('')), 1, 1, '') PORODate
						) D
						--Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or sq.StatusId=@StatusID))
						Group By SQ.ReceivingReconciliationId,D.PORODate
						)
						,Result AS(
						Select M.ReceivingReconciliationId,M.ReceivingReconciliationNumber,M.InvoiceNum as 'InvoiceNum',M.StatusId,M.Status as 'Status',M.VendorId,M.VendorName,IsNull(M.CurrencyId,0) as 'CurrencyId',M.CurrencyName,M.OpenDate,
									M.OriginalTotal,M.RRTotal,M.InvoiceTotal,M.DIfferenceAmount,M.TotalAdjustAmount,M.CreatedBy,M.UpdatedBy,M.CreatedDate,M.UpdatedDate,M.IsDeleted,M.IsActive,
									M.LastMSLevel,M.AllMSlevels,CASE WHEN M.[Type] = 1 THEN PT.PartNumber ELSE PTRO.PartNumber END as 'PartNumber',CASE WHEN M.[Type] = 1 THEN PT.PartNumberType ELSE PTRO.PartNumberType END as 'PartNumberType',
									CASE WHEN M.[Type] = 1 THEN PTE.PORODate ELSE PTERO.PORODate END as 'PORODate',CASE WHEN M.[Type] = 1 THEN PTE.PORODateType ELSE PTERO.PORODateType END as 'PORODateType'
									from Main M 
						Left Join PartCTE PT On M.ReceivingReconciliationId=PT.ReceivingReconciliationId
						Left Join PartDateCTE PTE On M.ReceivingReconciliationId=PTE.ReceivingReconciliationId
						Left Join PartROCTE PTRO On M.ReceivingReconciliationId=PTRO.ReceivingReconciliationId
						Left Join PartRODateCTE PTERO On M.ReceivingReconciliationId=PTERO.ReceivingReconciliationId
						Where (
						(@GlobalFilter <>'' AND (
						(M.ReceivingReconciliationNumber like '%' +@GlobalFilter+'%' ) OR
								(M.InvoiceNum like '%' +@GlobalFilter+'%') OR
								--(M.[Status] like '%' +@GlobalFilter+'%') OR
								(M.VendorName like '%' +@GlobalFilter+'%') OR
								--(PartNumberType like '%' +@GlobalFilter+'%') OR  
								(CASE WHEN M.[Type] = 1 THEN PT.PartNumberType ELSE PTRO.PartNumberType END like '%' +@GlobalFilter+'%') OR  
								(M.CurrencyName like '%' +@GlobalFilter+'%')
								--(M.CreatedBy like '%' +@GlobalFilter+'%') OR
								--(M.UpdatedBy like '%' +@GlobalFilter+'%') 
								))
								OR   
								(@GlobalFilter='' AND 
								(IsNull(@ReceivingReconciliationNumber,'') ='' OR M.ReceivingReconciliationNumber like '%'+@ReceivingReconciliationNumber+'%') and 
								(IsNull(@InvoiceNum,'') ='' OR M.InvoiceNum like '%'+@InvoiceNum+'%') and
								--(IsNull(@Status,'') ='' OR M.Status like '%'+ @Status+'%') and
								(IsNull(@VendorName,'') =''  OR M.VendorName like '%'+@VendorName+'%') and
								--(IsNull(@Status,'') =''  OR M.[Status] like '%'+@Status+'%') and
								(IsNull(@CurrencyName,'') =''  OR M.CurrencyName like '%'+@CurrencyName+'%') and
								--(IsNull(@PartNumberType,'') =''  OR PT.PartNumberType like '%'+@PartNumberType+'%') and
								(IsNull(@PartNumberType,'') =''  OR CASE WHEN M.[Type] = 1 THEN PT.PartNumberType ELSE PTRO.PartNumberType END like '%'+@PartNumberType+'%') and
								--(IsNull(@CreatedBy,'') =''  OR M.CreatedBy like '%'+@CreatedBy+'%') and
								--(IsNull(@UpdatedBy,'') =''  OR M.UpdatedBy like '%'+@UpdatedBy+'%') and
								(@OriginalTotal is  null or M.OriginalTotal=@OriginalTotal) and
								(@RRTotal is  null or M.RRTotal=@RRTotal) and
								(@InvoiceTotal is  null or M.InvoiceTotal=@InvoiceTotal) and
								(@DIfferenceAmount is  null or M.DIfferenceAmount=@DIfferenceAmount) and
								(IsNull(@PORODateType,'') ='' OR Cast(PTE.PORODateType as Date)=Cast(@PORODateType as date))  
								--(@SoAmount is  null or M.SoAmount=@SoAmount) and
								--(@OpenDate is  null or Cast(M.OpenDate as date)=Cast(@OpenDate as date))
								--(IsNull(@PartNumberType,'') ='' OR PT.PartNumberType like '%'+@PartNumberType+'%') and
								--(IsNull(@PartDescriptionType,'') ='' OR PD.PartDescriptionType like '%'+@PartDescriptionType+'%') and
								--(IsNull(@CreatedDate,'') ='' OR Cast(M.CreatedDate as Date)=Cast(@CreatedDate as date)) and
								--(IsNull(@UpdatedDate,'') ='' OR Cast(M.UpdatedDate as date)=Cast(@UpdatedDate as date))
								)
								)
						),CTE_Count AS (Select COUNT(ReceivingReconciliationId) AS NumberOfItems FROM Result)
						SELECT ReceivingReconciliationId,ReceivingReconciliationNumber,InvoiceNum,StatusId,Status,VendorId,VendorName,CurrencyId,CurrencyName,OpenDate
						,OriginalTotal,RRTotal,InvoiceTotal,DIfferenceAmount,TotalAdjustAmount,CreatedDate,UpdatedDate,NumberOfItems,CreatedBy,UpdatedBy,LastMSLevel,AllMSlevels,PartNumber,PartNumberType,PORODate,PORODateType
						FROM Result,CTE_Count
						ORDER BY  
						CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONNUMBER')  THEN ReceivingReconciliationNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='VENDORNAME')  THEN VendorName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CURRENCYNAME')  THEN CurrencyName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONNUMBER')  THEN ReceivingReconciliationNumber END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='RECEIVINGRECONCILIATIONID')  THEN ReceivingReconciliationId END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='INVOICENUM')  THEN InvoiceNum END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='VENDORNAME')  THEN VendorName END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CURRENCYNAME')  THEN CurrencyName END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC
						OFFSET @RecordFrom ROWS 
						FETCH NEXT @PageSize ROWS ONLY
					END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchSOQViewData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PageNumber, '') + ''
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