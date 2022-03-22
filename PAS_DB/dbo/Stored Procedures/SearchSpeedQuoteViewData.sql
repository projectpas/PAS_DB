-- ==================================================
-- Author:		Deep Patel
-- Create date: 3-Sep-2021
-- Description:	Get Search Data for Speed Quote List
-- ==================================================
CREATE PROCEDURE [dbo].[SearchSpeedQuoteViewData]
	-- Add the parameters for the stored procedure here
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@SpeedQuoteNumber varchar(50)=null,
	--@SalesOrderNumber varchar(50)=null,
	@CustomerName varchar(50)=null,
	@CustomerCode varchar(50)='',
	@Status varchar(50)=null,
    @QuoteAmount numeric(18,4)=null,
    @SoAmount numeric(18,4)=null,
    @QuoteDate datetime=null,
    @SalesPerson varchar(50)=null,
    --@PriorityType varchar(50)=null,
    @PartNumberType varchar(50)=null,
    @PartDescriptionType varchar(50)=null,
    @CustomerReference varchar(50)=null,
    @CustomerType varchar(50)=null,
	@VersionNumber varchar(50)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,
	@MasterCompanyId int = null,
	@LeadSourceName varchar(50)='',
	@Probability varchar(50)='',
	@QuoteExpireDate datetime=null,
	@AccountTypeName varchar(50)='',
	@LeadSourceReference varchar(50)='',
	@ConditionCodeType varchar(50)='',
	@EmployeeId bigint

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
					Set @SortColumn=Upper('CreatedDate')
				End 
				Else
				Begin 
					Set @SortColumn=Upper(@SortColumn)
				End

				If @QuoteAmount=0
				Begin 
					Set @QuoteAmount=null
				End
		
				If @SoAmount=0
				Begin 
					Set @SoAmount=null
				End


				If @StatusID=0
				Begin 
					Set @StatusID=null
				End 

				If @Status='0'
				Begin
					Set @Status=null
				End
				DECLARE @MSModuleID INT = 27; -- Speed Quote Management Structure Module ID
				;With Main AS(
						Select DISTINCT SOQ.SpeedQuoteId,SOQ.SpeedQuoteNumber,SOQ.OpenDate,C.CustomerId,C.Name,C.CustomerCode,MST.Name as 'Status',
						(E.FirstName+' '+E.LastName)as SalesPerson,CT.CustomerTypeName,
						SOQ.CreatedDate,SOQ.UpdatedDate,SOQ.StatusId,SOQ.CreatedBy,SOQ.UpdatedBy,
						A.SoAmount,
						dbo.GenearteVersionNumber(SOQ.Version) as 'VersionNumber',SOQ.IsNewVersionCreated,SOQ.CustomerReference,
						SOQ.QuoteExpireDate,SOQ.AccountTypeName,SOQ.LeadSourceReference,
						SOQ.LeadSourceName,P.PercentValue as 'Probability'
						from dbo.SpeedQuote SOQ WITH (NOLOCK) Inner Join MasterSalesOrderQuoteStatus MST WITH (NOLOCK) on SOQ.StatusId=MST.Id
						Inner Join Customer C WITH (NOLOCK) on SOQ.CustomerId=C.CustomerId
						Inner Join CustomerType CT WITH (NOLOCK) on SOQ.AccountTypeId=CT.CustomerTypeId
						Left Join Employee E WITH (NOLOCK) on  E.EmployeeId=SOQ.SalesPersonId --and SOQ.SalesPersonId is not null
						--Left Join SalesOrder SO WITH (NOLOCK) on SO.SalesOrderQuoteId=SOQ.SalesOrderQuoteId and SO.SalesOrderQuoteId is not Null
						INNER JOIN dbo.SalesOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @MSModuleID AND MSD.ReferenceID = SOQ.SpeedQuoteId
						INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON SOQ.ManagementStructureId = RMS.EntityStructureId
						INNER JOIN dbo.EmployeeUserRole EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
						Left join [Percent] p WITH (NOLOCK) on P.PercentId = SOQ.ProbabilityId
						Outer Apply(
							Select SUM(UnitSalePrice) as SoAmount from SpeedQuotePart 
							Where SpeedQuoteId=SOQ.SpeedQuoteId
						) A
						--Outer Apply (
						--	Select SUM(S.UnitCost) as 'QuoteAmount' from SpeedQuotePart S
						--	Where S.SpeedQuoteId=SOQ.SpeedQuoteId
						--) B
						Where (SOQ.IsDeleted=@IsDeleted) and (@StatusID is null or SOQ.StatusId=@StatusID) AND SOQ.MasterCompanyId = @MasterCompanyId),PartCTE AS(
						Select SQ.SpeedQuoteId,(Case When Count(SP.SpeedQuotePartId) > 1 Then 'Multiple' ELse A.PartNumber End)  as 'PartNumberType',A.PartNumber from SpeedQuote SQ WITH (NOLOCK)
						Left Join SpeedQuotePart SP WITH (NOLOCK) On SQ.SpeedQuoteId=SP.SpeedQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0
						Outer Apply(
							SELECT 
							   STUFF((SELECT ',' + I.partnumber
									  FROM SpeedQuotePart S WITH (NOLOCK)
									  Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.SpeedQuoteId=SQ.SpeedQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0
									  FOR XML PATH('')), 1, 1, '') PartNumber
						) A
						Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or sq.StatusId=@StatusID))
						Group By SQ.SpeedQuoteId,A.PartNumber
						),PartDescCTE AS(
						Select SQ.SpeedQuoteId,(Case When Count(SP.SpeedQuotePartId) > 1 Then 'Multiple' ELse A.PartDescription End)  as 'PartDescriptionType',A.PartDescription from SpeedQuote SQ WITH (NOLOCK)
						Left Join SpeedQuotePart SP WITH (NOLOCK) On SQ.SpeedQuoteId=SP.SpeedQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0
						Outer Apply(
							SELECT 
							   STUFF((SELECT ', ' + I.PartDescription
									  FROM SpeedQuotePart S WITH (NOLOCK)
									  Left Join ItemMaster I WITH (NOLOCK) On S.ItemMasterId=I.ItemMasterId
									  Where S.SpeedQuoteId=SQ.SpeedQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0
									  FOR XML PATH('')), 1, 1, '') PartDescription
						) A
						Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or SQ.StatusId=@StatusID))
						Group By SQ.SpeedQuoteId,A.PartDescription
						),
						--PriorityCTE AS(
						--Select SQ.SpeedQuoteId,(Case When Count(SP.SpeedQuotePartId) > 1 Then 'Multiple' ELse A.PriorityDescription End)  as 'PriorityType',A.PriorityDescription from SpeedQuote SQ WITH (NOLOCK)
						--Left Join SpeedQuotePart SP WITH (NOLOCK) On SQ.SpeedQuoteId=SP.SpeedQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0
						--Outer Apply(
						--	SELECT 
						--	   STUFF((SELECT ', ' + P.Description
						--			  FROM SpeedQuotePart S WITH (NOLOCK)
						--			  Left Join Priority P WITH (NOLOCK) On P.PriorityId=S.PriorityId
						--			  Where S.SpeedQuoteId=SQ.SpeedQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0
						--			  FOR XML PATH('')), 1, 1, '') PriorityDescription
						--) A
						--Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or SQ.StatusId=@StatusID)) 
						--Group By SQ.SpeedQuoteId,A.PriorityDescription
						--),
						PartConditionCodeCTE AS(
						Select SQ.SpeedQuoteId,(Case When Count(SP.SpeedQuotePartId) > 1 Then 'Multiple' ELse A.ConditionCode End)  as 'ConditionCodeType',A.ConditionCode from SpeedQuote SQ WITH (NOLOCK)
						Left Join SpeedQuotePart SP WITH (NOLOCK) On SQ.SpeedQuoteId=SP.SpeedQuoteId AND SP.IsActive = 1 AND SP.IsDeleted = 0
						Outer Apply(
							SELECT 
							   STUFF((SELECT DISTINCT ', ' + cn.Code
									  FROM SpeedQuotePart S WITH (NOLOCK)
									  Inner join Condition cn WITH (NOLOCK) on cn.ConditionId = S.ConditionId
									  Where S.SpeedQuoteId=SQ.SpeedQuoteId AND S.IsActive = 1 AND S.IsDeleted = 0
									  FOR XML PATH('')), 1, 1, '') ConditionCode
						) A
						Where ((SQ.IsDeleted=@IsDeleted) and (@StatusID is null or SQ.StatusId=@StatusID))
						Group By SQ.SpeedQuoteId,A.ConditionCode
						),
						Result AS(
						Select M.SpeedQuoteId,M.SpeedQuoteNumber,M.OpenDate as 'QuoteDate',M.CustomerId,M.Name as 'CustomerName',M.Status,
									M.VersionNumber,IsNull(M.SoAmount,0) as 'QuoteAmount',M.IsNewVersionCreated,M.StatusId,M.CustomerReference,
									--PR.PriorityDescription as 'Priority',PR.PriorityType,
									M.SalesPerson,PT.PartNumber,PT.PartNumberType,PD.PartDescription,
									PD.PartDescriptionType,M.CustomerTypeName as 'CustomerType',IsNULL(M.SoAmount,0) as 'SoAmount',M.CreatedDate,
									M.UpdatedDate,M.CreatedBy,M.UpdatedBy,M.CustomerCode,M.QuoteExpireDate,M.AccountTypeName,M.LeadSourceReference,M.LeadSourceName,M.Probability,
									PC.ConditionCode,PC.ConditionCodeType
									from Main M 
						Left Join PartCTE PT On M.SpeedQuoteId=PT.SpeedQuoteId
						Left Join PartDescCTE PD on PD.SpeedQuoteId=M.SpeedQuoteId
						--Left Join PriorityCTE PR on PR.SpeedQuoteId=M.SpeedQuoteId
						Left Join PartConditionCodeCTE PC on PC.SpeedQuoteId=M.SpeedQuoteId
						Where (
						(@GlobalFilter <>'' AND ((M.SpeedQuoteNumber like '%' +@GlobalFilter+'%' ) OR (M.SpeedQuoteNumber like '%' +@GlobalFilter+'%') OR
								--(M.SalesOrderNumber like '%' +@GlobalFilter+'%') OR
								(M.Name like '%' +@GlobalFilter+'%') OR
								(M.CustomerCode like '%' +@GlobalFilter+'%') OR
								(M.Status like '%' +@GlobalFilter+'%') OR
								(M.VersionNumber like '%' +@GlobalFilter+'%') OR
								(M.SalesPerson like '%' +@GlobalFilter+'%') OR
								--(PR.PriorityType like '%' +@GlobalFilter+'%') OR
								(PT.PartNumberType like '%' +@GlobalFilter+'%') OR
								(PD.PartDescriptionType like '%' +@GlobalFilter+'%') OR
								(M.CustomerReference like '%' +@GlobalFilter+'%') OR
								(M.CustomerTypeName like '%' +@GlobalFilter+'%') OR 
								(M.CreatedBy like '%' +@GlobalFilter+'%') OR
								(M.UpdatedBy like '%' +@GlobalFilter+'%') OR
								(M.LeadSourceName like '%' +@GlobalFilter+'%') OR
								(M.Probability like '%' +@GlobalFilter+'%') OR
								--(M.QuoteExpireDate like '%' +@GlobalFilter+'%') OR
								(M.AccountTypeName like '%' +@GlobalFilter+'%') OR
								(M.LeadSourceReference like '%' +@GlobalFilter+'%') OR
								(PC.ConditionCodeType like '%' +@GlobalFilter+'%')
								))
								OR   
								(@GlobalFilter='' AND (IsNull(@SpeedQuoteNumber,'') ='' OR M.SpeedQuoteNumber like '%'+@SpeedQuoteNumber+'%') and 
								--(IsNull(@SalesOrderNumber,'') ='' OR M.SalesOrderNumber like '%'+@SalesOrderNumber+'%') and
								(IsNull(@CustomerName,'') ='' OR M.Name like '%'+ @CustomerName+'%') and
								(IsNull(@CustomerCode,'') ='' OR M.CustomerCode like '%'+ @CustomerCode+'%') and
								(IsNull(@Status,'') =''  OR M.Status like '%'+@Status+'%') and
								(@QuoteAmount is  null or M.SoAmount=@QuoteAmount) and
								(@SoAmount is  null or M.SoAmount=@SoAmount) and
								(@QuoteDate is  null or Cast(M.OpenDate as date)=Cast(@QuoteDate as date)) and
								(IsNull(@SalesPerson,'') ='' OR M.SalesPerson like '%'+@SalesPerson+'%') and
								--(IsNull(@PriorityType,'') ='' OR PR.PriorityType like '%'+ @PriorityType+'%') and
								(IsNull(@PartNumberType,'') ='' OR PT.PartNumberType like '%'+@PartNumberType+'%') and
								(IsNull(@PartDescriptionType,'') ='' OR PD.PartDescriptionType like '%'+@PartDescriptionType+'%') and
								(IsNull(@CustomerReference,'') ='' OR M.CustomerReference like '%'+@CustomerReference+'%') and
								(IsNull(@CustomerType,'') ='' OR M.CustomerTypeName like '%'+@CustomerType+'%') and
								(IsNull(@VersionNumber,'') ='' OR M.VersionNumber like '%'+@VersionNumber+'%') and
								(IsNull(@CreatedBy,'') ='' OR M.CreatedBy like '%'+@CreatedBy+'%') and
								(IsNull(@UpdatedBy,'') ='' OR M.UpdatedBy like '%'+@UpdatedBy+'%') and
								(IsNull(@CreatedDate,'') ='' OR Cast(M.CreatedDate as Date)=Cast(@CreatedDate as date)) and
								(IsNull(@UpdatedDate,'') ='' OR Cast(M.UpdatedDate as date)=Cast(@UpdatedDate as date)) and
								(IsNull(@LeadSourceName,'') ='' OR M.LeadSourceName like  '%'+@LeadSourceName+'%') and
								(IsNull(@Probability,'') ='' OR M.Probability like  '%'+@Probability+'%') and
								(IsNull(@QuoteExpireDate,'') ='' OR Cast(M.QuoteExpireDate as Date)=Cast(@QuoteExpireDate as date)) and
								(IsNull(@AccountTypeName,'') ='' OR M.AccountTypeName like  '%'+@AccountTypeName+'%') and
								(IsNull(@LeadSourceReference,'') ='' OR M.LeadSourceReference like  '%'+@LeadSourceReference+'%') and
								(IsNull(@ConditionCodeType,'') ='' OR PC.ConditionCodeType like '%'+@ConditionCodeType+'%'))
								)
					
			
						), CTE_Count AS (Select COUNT(SpeedQuoteId) AS NumberOfItems FROM Result)
						SELECT SpeedQuoteId,SpeedQuoteNumber,QuoteDate,CustomerId,CustomerName,Status,VersionNumber,QuoteAmount,IsNewVersionCreated,StatusId
						,CustomerReference,
						--Priority,PriorityType,
						SalesPerson,PartNumber,PartNumberType,PartDescription,PartDescriptionType,CustomerType,ConditionCode,ConditionCodeType,
						--SalesOrderNumber,
						CreatedDate,UpdatedDate,NumberOfItems,CreatedBy,UpdatedBy,CustomerCode,LeadSourceName,Probability,QuoteExpireDate,AccountTypeName,LeadSourceReference FROM Result,CTE_Count
						ORDER BY  
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='SPEEDQUOTENUMBER')  THEN SpeedQuoteNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEDATE')  THEN QuoteDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='STATUS')  THEN Status END ASC,
						--CASE WHEN (@SortOrder=1 and @SortColumn='SALESORDERNUMBER')  THEN SalesOrderNumber END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='SOAMOUNT')  THEN SoAmount END ASC,
						--CASE WHEN (@SortOrder=1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='SALESPERSON')  THEN SalesPerson END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='LEADSOURCEANAME')  THEN LeadSourceName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='PROBABILITY')  THEN Probability END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='QUOTEEXPIREDATE')  THEN QuoteExpireDate END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='ACCOUNTTYPENAME')  THEN AccountTypeName END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='LEADSOURCEREFERENCE')  THEN LeadSourceReference END ASC,
						CASE WHEN (@SortOrder=1 and @SortColumn='CONDITIONCODETYPE')  THEN ConditionCodeType END ASC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDDATE')  THEN CreatedDate END Desc,
						--CASE WHEN (@SortOrder=-1 and @SortColumn='SALESORDERQUOTENUMBER')  THEN SalesOrderQuoteNumber END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='VERSIONNUMBER')  THEN VersionNumber END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEDATE')  THEN QuoteDate END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='STATUS')  THEN Status END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='SPEEDQUOTENUMBER')  THEN SpeedQuoteNumber END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PARTNUMBERTYPE')  THEN PartNumberType END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PARTDESCRIPTIONTYPE')  THEN PartDescriptionType END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERNAME')  THEN CustomerName END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERCODE')  THEN CustomerCode END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERTYPE')  THEN CustomerType END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CUSTOMERREFERENCE')  THEN CustomerReference END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEAMOUNT')  THEN QuoteAmount END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='SOAMOUNT')  THEN SoAmount END Desc,
						--CASE WHEN (@SortOrder=-1 and @SortColumn='PRIORITYTYPE')  THEN PriorityType END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='SALESPERSON')  THEN SalesPerson END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDDATE')  THEN UpdatedDate END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
						CASE WHEN (@SortOrder=-1 and @SortColumn='LEADSOURCEANAME')  THEN LeadSourceName END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='PROBABILITY')  THEN Probability END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='QUOTEEXPIREDATE')  THEN QuoteExpireDate END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='ACCOUNTTYPENAME')  THEN AccountTypeName END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='LEADSOURCEREFERENCE')  THEN LeadSourceReference END Desc,
						CASE WHEN (@SortOrder=-1 and @SortColumn='CONDITIONCODETYPE')  THEN ConditionCodeType END Desc
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
              , @AdhocComments     VARCHAR(150)    = 'SearchSpeedQuoteViewData' 
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